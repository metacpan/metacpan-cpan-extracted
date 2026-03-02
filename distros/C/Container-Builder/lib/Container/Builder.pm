package Container::Builder;

use v5.40;
use feature 'class';
no warnings 'experimental::class';

our $VERSION = '0.09';

use Cwd;
use LWP::Simple;
use IO::Uncompress::Gunzip qw(gunzip);
use DPKG::Packages::Parser;
use File::Basename;
use Path::Class::Iterator;

use Container::Builder::Tar;
use Container::Builder::Config;
use Container::Builder::Manifest;
use Container::Builder::Index;

use Container::Builder::Layer;
use Container::Builder::Layer::DebianPackageFile;
use Container::Builder::Layer::Tar;
use Container::Builder::Layer::SingleFile;

class Container::Builder {
	field $compress_deb_tar :param = 1;
	field $debian_pkg_hostname :param;
	field $cache_folder :param = '';
	field $enable_packages_cache :param = 0;
	field $packages_file :param = 'Packages';

	field $os = 'debian';
	field $arch = 'amd64';
	field $os_version :param = 'bookworm';
	field @layers = ();
	field $original_dir = Cwd::getcwd();
	field $runas = 'root';
	field $work_dir = '/';
	field @entry = ();
	field @cmd = ();
	field @env = ();
	field %deb_packages = ();
	field @dirs = ();
	field @users = ();
	field @groups = ();
	field $packages; 

	# Podman will use the Container::Builder::Config digest as the identifier for your imported container. Users might want to have this ID.
	field $ctr_digest = undef;

	method _parse_packages(@fields) {
		if($enable_packages_cache && !-r $packages_file) { # Our cache file does not exist
			$debian_pkg_hostname =~ s/[^\w\-\.]//g; # a light scrubbing on the hostname... But we still assume the caller does the scrubbing!
			my $packagesgz = LWP::Simple::get("https://$debian_pkg_hostname/debian/dists/$os_version/main/binary-amd64/Packages.gz");
			IO::Uncompress::Gunzip::gunzip(\$packagesgz => $packages_file);
			$packages = DPKG::Packages::Parser->new('file' => $packages_file);
		} elsif($enable_packages_cache) { # Our cache file exists
			$packages = DPKG::Packages::Parser->new('file' => $packages_file);
		} elsif(!$enable_packages_cache) { # don't drop anything to disk
			$debian_pkg_hostname =~ s/[^\w\-\.]//g; # a light scrubbing on the hostname... But we still assume the caller does the scrubbing!
			my $packagesgz = LWP::Simple::get("https://$debian_pkg_hostname/debian/dists/$os_version/main/binary-amd64/Packages.gz");
			my $packages_raw;
			IO::Uncompress::Gunzip::gunzip(\$packagesgz => \$packages_raw);
			open(my $f, '<', \$packages_raw);
			$packages = DPKG::Packages::Parser->new(fh => $f);
		}
		$packages->parse(@fields);
	}

	method _get_deb_package($package_name) {
		if($cache_folder) {
			my $cache_folder_ws = $cache_folder . (substr($cache_folder, -1) eq '/' ? '' : '/'); # ws = with slash
			if(-d $cache_folder_ws && -r $cache_folder_ws . $package_name . '.deb') {
				local $/ = undef;
				open(my $deb, '<', $cache_folder_ws . $package_name . '.deb') or die "Cannot open $cache_folder_ws$package_name.deb\n";
				my $deb_content = <$deb>;
				close($deb);
				return $deb_content;
			}
		}

		$self->_parse_packages('Filename', 'Depends') if !$packages; # lazy load on first call
		my $pkg = $packages->get_package($package_name);
		return 0 if !$pkg;

		my $filepath = $pkg->{Filename};
		my ($filename) = $filepath =~ m/([^\/]+)$/;
		my $url = "https://debian.inf.tu-dresden.de/debian/" . $filepath;
		my $lwp = LWP::UserAgent->new();
		my $response = $lwp->get($url);
		if(!$response->is_success) { # Added because my base perl LWP didn't have the https package to support https...
			die "Call to Debian package repo failed: " . $response->status_line;
		}
		my $package_content = $response->decoded_content;
		die "unable to get package content with LWP::Simple" if !$package_content;
		return $package_content;
	}

	method add_deb_package($package_name) {
		return 0 if $deb_packages{$package_name};
		my $package_content = $self->_get_deb_package($package_name);
		return 0 if ! $package_content;

		if($cache_folder) {
			my $cache_folder_ws = $cache_folder . (substr($cache_folder, -1) eq '/' ? '' : '/'); # ws = with slash
			if(!-r $cache_folder_ws . $package_name . '.deb') {
				open(my $f, '>', $cache_folder_ws . $package_name . '.deb') or die "cannot open $cache_folder_ws$package_name.deb\n";
				print $f $package_content;
				close($f);
			}
		}

		# Before adding the package as a layer, get the dependencies and add those
		$deb_packages{$package_name} = 1;
		$self->_parse_packages('Filename', 'Depends') if !$packages; # lazy load on first call
		my $pkg = $packages->get_package($package_name);
		foreach(@{$pkg->{Depends}}) {
			if(ref eq 'ARRAY') {
				# TODO: there's no way we can make an intelligent decision here, we can check if any of these have already been added or not. If one of the options was already added, we can skip choosing; if none was already added, take the first one.
				$self->add_deb_package(${$_}[0]->{name});
			} elsif(ref eq 'HASH') {
				$self->add_deb_package($_->{name});
			}
		}

		push @layers, Container::Builder::Layer::DebianPackageFile->new(comment => $package_name, data => $package_content, compress => $compress_deb_tar);
	}

	# Create a layer that adds a package to the container
	method add_deb_package_from_file($filepath_deb) {
		die "Unable to read $filepath_deb\n" if !-r $filepath_deb;
		push @layers, Container::Builder::Layer::DebianPackageFile->new(comment => $filepath_deb, file => $filepath_deb, compress => $compress_deb_tar);
	}

	method extract_from_deb($package_name, $files_to_extract) {
		my $deb_archive = $self->_get_deb_package($package_name);
		if($deb_archive) {
			# Read the tar -> with our own class because Archive::Tar doesn't read from a string...
			my $deb = Container::Builder::Layer::DebianPackageFile->new(comment => $package_name, data => $deb_archive, compress => $compress_deb_tar);
			my $tar = $deb->generate_artifact();
			my $tar_builder = Container::Builder::Tar->new();
			my $result_tar = '';
			foreach(@$files_to_extract) {
				my $tar_file = '';
				if($_ =~ /\*$/) {
					$tar_file = $tar_builder->extract_wildcard_files($tar, $_);
				} else {
					$tar_file = $tar_builder->extract_file($tar, $_);
				}
				$result_tar .= $tar_file;
			}
			$result_tar .= "\x00" x 1024; # two empty blocks
			push @layers, Container::Builder::Layer::Tar->new(comment => "custom $package_name", data => $result_tar);
		} else {
			die "Did not find deb package with name $package_name\n";
		}
	}

	# Create a layer that has one file
	method add_file($file_on_disk, $location_in_ctr, $mode, $user, $group) {
		die "Cannot read file at $file_on_disk\n" if !-r $file_on_disk;
		push @layers, Container::Builder::Layer::SingleFile->new(comment => $location_in_ctr, file => $file_on_disk, dest => $location_in_ctr, mode => $mode, user => $user, group => $group);
	}

	method add_file_from_string($data, $location_in_ctr, $mode, $user, $group) {
		push @layers, Container::Builder::Layer::SingleFile->new(comment => $location_in_ctr, data => $data, dest => $location_in_ctr, mode => $mode, user => $user, group => $group);
	}

	method copy($local_dirpath, $location_in_ctr, $mode, $user, $group) {
		if(!-d $local_dirpath) {
			die "Container::Builder::copy() only supports directories. Use add_file() or add_file_from_string() if you need to copy one file\n";
		}
		$local_dirpath .= (substr($local_dirpath, -1) eq '/' ? '' : '/');
		my $local_basename = basename($local_dirpath);
		my $prefix_path = $location_in_ctr;
		if(substr($location_in_ctr, -1) eq '/') {# say "ctr location ends with /, so that means our folder $local_basename becomes a subfolder";
			$prefix_path .= $local_basename . '/';
		} else {
			my $remote_basename = basename($location_in_ctr);
			#say "ctr location doesnt end with /, so that means our folder $local_basename gets renamed to $remote_basename";
			$prefix_path .= '/';
		}

		my $iterator = Path::Class::Iterator->new(root => $local_dirpath, follow_symlinks => 0, follow_hidden => 0);
		my $tar = Container::Builder::Tar->new();
		$tar->add_dir($prefix_path, $mode, $user, $group);
		until($iterator->done) {
			my $item = $iterator->next;
			if($item->is_dir()) {
				my $remote_dir = $prefix_path . substr($item, length($local_dirpath));
				my $mode = (stat($item))[2] & 07777;
				$tar->add_dir($remote_dir, $mode, $user, $group);
			} else {
				my $remote_file = $prefix_path . substr($item, length($local_dirpath));
				my $mode = (stat($item))[2] & 07777;
				local $/ = undef;
				open(my $file, '<', $item) or die "cannot open file $item for reading\n";
				my $data = <$file>;
				$tar->add_file($remote_file, $data, $mode, $user, $group);
			}
		}
		push @layers, Container::Builder::Layer::Tar->new(comment => $local_dirpath, data => $tar->get_tar());
	}

	# Create a layer that creates a directory in the container
	method create_directory($path, $mode, $uid, $gid) {
		my %dir = (path => $path, mode => $mode, uid => $uid, gid => $gid);
		push @dirs, \%dir;
	}

	# Create a layer that adds a user to the container
	# this is a wrapper to make a change to passwd?
	method add_user($name, $uid, $main_gid, $shell, $homedir) {
		$name =~ s/[^a-z]//ig;
		$uid =~ s/[^\d]//g;
		$main_gid =~ s/[^\d]//g;
		die "Conflicting user" if grep { $_->{name} eq $name || $_->{uid} == $uid || $_->{gid} == $main_gid } @users;
		my %new_user = (name => $name, uid => $uid, gid => $main_gid, shell => $shell, homedir => $homedir);
		push @users, \%new_user;
	}

	# Create a layer that adds a group to the container
	method add_group($name, $gid) {
		$name =~ s/[^a-z]//ig;
		$gid =~ s/[^\d]//g;
		die "Conflicting with existing group\n" if grep {$_->{name} eq $name || $_->{gid} == $gid } @groups;
		my %new_group = (name => $name, gid => $gid);
		push @groups, \%new_group;
	}

	# similar to USER in Dockerfile
	method runas_user($user) {
		my $found_user = 0;
		foreach(@users) {
			$found_user = 1 if $_->{name} eq $user;
		}
		die "Cannot set the USER to $user if it's not part of the users in the container\n" if !$found_user;
		$runas = $user;
	}

	# Sets an environment variable, similar to ENV in Dockerfile
	method set_env($key, $value) {
		# TODO: probably needs some escaping for nasty value's or values with an '=', ...
		push @env, "$key=$value";
	}

	# Set entrypoint
	method set_entry(@command_str) {
		die "Entrypoint/Command list is empty\n" if !@command_str;
		push @entry, shift(@command_str);
		push @cmd, @command_str;
	}

	method set_work_dir($workdirectory) {
		$work_dir = $workdirectory;
	}

	method build($filename_result = '') {

		# Make 1 layer with all the base files
		my $tar = Container::Builder::Tar->new();

			foreach(@dirs) {
				$tar->add_dir($_->{path}, $_->{mode}, $_->{uid}, $_->{gid});
			}

			# Generate /etc/group file
			my $etcgroup = '';
			map { $etcgroup .= $_->{name} . ':x:' . $_->{gid} . ':' . $/ } @groups;
			$tar->add_file('/etc/group', $etcgroup, 0644, 0, 0);

			# Generate /etc/passwd file
			my $etcpasswd = '';
			# example line: root:x:0:0:root:/root:/bin/bash
			map { $etcpasswd .= $_->{name} . ':x:' . $_->{uid} . ':' . $_->{gid} . ':' . $_->{name} . ':' . $_->{homedir} . ':' . $_->{shell} . $/ } @users;
			$tar->add_file('/etc/passwd', $etcpasswd, 0644, 0, 0);
	
		my $tar_content = $tar->get_tar();
		unshift @layers, Container::Builder::Layer::Tar->new(comment => 'Base files', data => $tar_content);

		$tar = Container::Builder::Tar->new();
		$tar->add_dir('blobs/', 0755, 0, 0);
		$tar->add_dir('blobs/sha256/', 0755, 0, 0);
		# Add all layers
		foreach(@layers) {
			my $data = $_->generate_artifact();
			my $digest = $_->get_digest();
			$tar->add_file('blobs/sha256/' . $digest, $data, 0644, 0, 0);
		}

		# We need to generate our artifacts before we can call the Config, because we need the sizes and digests of the layers...
		my $config = Container::Builder::Config->new();
		my $config_json = $config->generate_config($runas, \@env, \@entry, \@cmd, $work_dir, \@layers);
		$tar->add_file('blobs/sha256/' . $config->get_digest(), $config_json, 0644, 0, 0);
		$ctr_digest = $config->get_digest();

		my $manifest = Container::Builder::Manifest->new();
		my $manifest_json = $manifest->generate_manifest($config->get_digest(), $config->get_size(), \@layers);
		$tar->add_file('blobs/sha256/' . $manifest->get_digest(), $manifest_json, 0644, 0, 0);

		my $oci_layout = '{"imageLayoutVersion": "1.0.0"}';
		$tar->add_file('oci-layout', '{"imageLayoutVersion": "1.0.0"}', 0644, 0, 0);
		my $index = Container::Builder::Index->new();
		$tar->add_file('index.json', $index->generate_index($manifest->get_digest(), $manifest->get_size()), 0644, 0, 0);

		if($filename_result) {
			open(my $o, '>', $filename_result) or die "cannot open $filename_result\n";
			print $o $tar->get_tar();
			close($o);
		} else {
			return $tar->get_tar();
		}
	}

	method get_digest() {
		die "Run build() first" if ! $ctr_digest;
		$ctr_digest;
	}

	method get_layers() {
		@layers
	}
}

1;
__END__

=encoding utf-8

=pod

=head1 NAME

Container::Builder - Build Container archives.

=head1 SYNOPSIS

  # See also the examples/ folder of this module.
  use v5.40;
  
  use Container::Builder;
  
  # Please use a Debian mirror close to you
  my $builder = Container::Builder->new(debian_pkg_hostname => 'debian.inf.tu-dresden.de');
  $builder->create_directory('/', 0755, 0, 0);
  $builder->create_directory('bin/', 0755, 0, 0);
  $builder->create_directory('tmp/', 01777, 0, 0);
  $builder->create_directory('root/', 0700, 0, 0);
  $builder->create_directory('home/', 0755, 0, 0);
  $builder->create_directory('home/larry/', 0700, 1337, 1337);
  $builder->create_directory('etc/', 0755, 0, 0);
  $builder->create_directory('app/', 0755, 1337, 1337);
  # C dependencies (to run a compiled executable)
  $builder->add_deb_package('libc-bin');
  $builder->add_deb_package('libc6');
  $builder->add_deb_package('gcc-12-base');
  $builder->add_deb_package('libgcc-s1');
  $builder->add_deb_package('libgomp1');
  $builder->add_deb_package('libstdc++6');
  # Perl base
  $builder->add_deb_package('libcrypt1');
  $builder->add_deb_package('perl-base');
  $builder->add_group('root', 0);
  $builder->add_group('tty', 5);
  $builder->add_group('staff', 50);
  $builder->add_group('larry', 1337);
  $builder->add_group('nobody', 65000);
  $builder->add_user('root', 0, 0, '/sbin/nologin', '/root');
  $builder->add_user('nobody', 65000, 65000, '/sbin/nologin', '/nohome');
  $builder->add_user('larry', 1337, 1337, '/sbin/nologin', '/home/larry');
  $builder->runas_user('larry');
  $builder->set_env('PATH', '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin');
  $builder->set_work_dir('/home/larry/');
  $builder->set_entry('perl', 'testproggie.pl');
  my $testproggie = <<'PROG';
  use v5.36;
  say "Hallo vriendjes en vriendinnetjes!";
  PROG
  $builder->add_file_from_string($testproggie, '/home/larry/testproggie.pl', 0644, 1337, 1337); # our program
  $builder->build('01-hello-world.tar');
  say "Now run: podman load -i 01-hello-world.tar";
  say "Then run: podman run " . substr($builder->get_digest(), 0, 12);

=head1 DESCRIPTION

Container::Builder builds a TAR archive that can be imported into Podman or Docker. It's main use is to craft specific, small containers based on Debian package (.deb) files. The type of functions to extend are similar to those that you can find in a Dockerfile. 

We use a Build pattern to build the archive. Most functions return quickly, and only the C<build()> function actually creates all the layers of the container and writes the result to disk.

Look into the C<examples/> folder for some examples to make working Perl (Dancer2) images.

B<Note>: This module is not production-ready! It's still in early stages of development and maturity.

=head1 METHODS

=over 1

=item new(debian_pkg_hostname => 'mirror.as35701.net', [compress_deb_tar => 1], [os_version => 'bookworm'], [cache_folder => 'artifacts/'], [enable_packages_cache => 0], [packages_file => 'Packages'])

I<the square brackets signify that the parameter is optional, not an array ref>

Create a Container::Builder object. Only the C<debian_pkg_hostname> parameter is required so you can pick a Debian mirror close to the geographical region from where the code is running. See L<https://www.debian.org/mirror/list>.

C<compress_deb_tar> compresses the debian TAR archives with Gzip before storing. You're trading build speeds in for less disk space.

C<os_version> controls which Debian Packages will be used to find the packages on the mirror.

When C<cache_folder> is defined, the folder will be used to store the downloaded deb packages and it will be used in subsequent runs as a cache so we don't retrieve it from the debian mirror every single time.

C<enable_packages_cache> will look for a Packages file defined by C<packages_file> option. If it doesn't exist, it will be downloaded from the Debian mirror. If it does exist, it will be read from disk instead of getting a fresh copy.

=item add_deb_package('libperl5.36')

Add a Debian package to the container. The C<data.tar> file inside the Debian package file (C<.deb>) will be stored as a layer in the resulting container. 

=item add_deb_package_from_file($filepath_deb)

Add a Debian package file to the container. The C<data.tar> file inside the Debian package file (C<.deb>) will be stored as a layer in the resulting container. 

=item extract_from_deb($package_name, $files_to_extract)

Extract certain files from the Debian package before storing as a layer. C<$package_name> is the name of the Debian package, C<$files_to_extract> is an array ref containing a list of files to extract. Rudimentary support for globs/wildcards (only useable at the end of the string).

I<This is an experimental method.>

=item add_file($file_on_disk, $location_in_ctr, $mode, $user, $group)

Adds the local file C<$file_on_disk> inside the container at location C<$location_in_ctr> with the specified C<$mode>, C<$user> and C<$group>.

=item add_file_from_string($data, $location_in_ctr, $mode, $user, $group)

Adds the data in the scalar C<$data> to the container at location C<$location_in_ctr> with the specified C<$mode>, C<$user> and C<$group>.

=item copy($local_dirpath, $location_in_ctr, $mode, $user, $group)

Recursively copy the C<$local_dirpath> directory into a layer of the container. The resulting path inside the container is defined by C<$location_in_ctr>. C<$mode> controls the directory permission of C<$location_in_ctr> only. Inner directories will have the permissions as on the local filesystem. All directories and files will be changed to be owned by C<$user> and C<$group>.

If C<$location_in_ctr> has a slash at the end, the last directory of C<$local_dirpath> will become a subdirectory of the path C<$location_in_ctr>. Otherwise, the last directory of C<$local_dirpath> will be renamed to the last directory of C<$location_in_ctr>.

For example C<copy('lib/', '/app/')> will create C</app/lib/> but C<copy('lib/', '/app')> will put all put the files and directories directly inside C</app>, there will be no C<lib> directory.

=item create_directory($path, $mode, $uid, $gid)

Create an empty directory at C<$path> inside the container with the specified C<$mode>, C<$user> and C<$group>.

=item add_user($name, $uid, $main_gid, $shell, $homedir)

Add a user to the container. This puts the user inside the C</etc/passwd> file.

=item add_group($name, $gid)

Add a group to the container. This puts the group inside the C</etc/group> file.

=item runas_user($user)

Specify the user to run the entrypoint as.

=item set_env($key, $value)

Add a environment variable to the container definition.

=item set_entry(@command_str)

Set the default entrypoint of the container.

=item set_work_dir($workdirectory)

Set the default working directory of the container.

=item build()

=item build('mycontainer.tar')

Build the container and write the result to the filepath specified. If no argument is given, the entire archive is returned as a scalar from the method.

=item get_digest()

Returns the digest of the embedded config file in the archive. This digest is used by tools such as podman as a unique ID to your container.

=item get_layers()

Returns a list of C<Container::Builder::Layer> objects as currently added to the Builder. 

Note: During build() extra layers can be added in the front or at the end of this list.

=back

=head1 AUTHOR

Adriaan Dens E<lt>adri@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2026- Adriaan Dens

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Google distroless|https://github.com/GoogleContainerTools/distroless> containers are the main inspiration for creating this module. The idea of creating minimal containers based on Debian packages comes from the Bazel build code in the linked repository that uses these packages to provide a minimal working container. My own examples do the same (and were an initial experiment to see if this approach would actually work).

=cut

