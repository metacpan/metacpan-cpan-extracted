package Dancer2::Plugin::LiteBlog::Scaffolder;
use Moo;
use Dancer2::Plugin::LiteBlog::Scaffolder::Data;
use Carp 'croak';
use File::Spec;
use File::Path qw(make_path);
use File::Slurp 'write_file';
use MIME::Base64;

=head1 LiteBlog Scaffolder - bootstrap your views for your LiteBlog site

This helper is here to get you strated in a snap with a sleek and responsive
design for your site.

=head1 USAGE

Right after having generated your Dancer2 app, inside the app directory, 
call C<liteblog-scaffold> to generate all default views and static files 
that are designed to work nicely with L<Dancer2::Plugin::LiteBlog>.

=cut

sub load {
    my $data = {};
    my $file;

    if (! defined Dancer2::Plugin::LiteBlog::Scaffolder::Data->build) {
        print "You seem to be running the scaffolder from the sources.\n";
        print "You have to build the scaffolder data first.\n";
        print "In your Dancer2-Plugin-LiteBlog source, run the following command: \n";
        print "\n";
        print "perl -Ilib -Idist dist/build.pl\n";
        exit 1;
    }

	while (my $line = <Dancer2::Plugin::LiteBlog::Scaffolder::Data::DATA>) {
        if ($line =~ /--- (.*)\n/) {
            $file = $1;
        $data->{$file} = "";
            next;
        }
        if (defined $file) {
            $data->{$file} .= $line;
        }
    }
	return $data;
}

sub base64_to_image {
    my ($base64_content, $output_path) = @_;

    # Decode the base64 string
    my $binary_data = decode_base64($base64_content);

    # Write the decoded binary data to a file
    write_file($output_path, {binmode => ':raw'}, $binary_data);
}

sub scaffold {
    my ($basedir, $force) = @_;

	my $data = load();
	foreach my $file_k (keys %$data) {
        my @subs = split('/', $file_k);
        my $filename = pop @subs;

        # Create the directory structure
        make_path(File::Spec->catfile($basedir, @subs));

        # Write the file to the appropriate path
		my $target = File::Spec->catfile($basedir, @subs, $filename);
		if (-e $target && !$force) {
			print "$target already exists, skipping\n";
		}
		else {
            my $create = 'Created';
            if ($force && -e $target) {
                unlink $target or croak "Unable to remove $target: $!";
                $create = 'Replaced';
            }

            if ($target =~ /\.(jpg|png)$/) {
                base64_to_image($data->{$file_k}, $target);
            }
            else {
                write_file($target, { binmode => ':encoding(UTF-8)'}, $data->{$file_k});
            }
			print "$create: $target\n";
		}
	}
}

1;
