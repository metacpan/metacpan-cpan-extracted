package App::Raps2;

use strict;
use warnings;
use 5.010;

use App::Raps2::Password;
use App::Raps2::UI;
use Carp qw(cluck confess);
use Config::Tiny;
use File::BaseDir qw(config_home data_home);
use File::Path qw(make_path);
use File::Slurp qw(slurp write_file);

our $VERSION = '0.54';

sub new {
	my ( $class, %opt ) = @_;
	my $self = {};

	$self->{xdg_conf} = config_home('raps2');
	$self->{xdg_data} = data_home('raps2');

	if ( not $opt{no_cli} ) {
		$self->{ui} = App::Raps2::UI->new();
	}

	$self->{default} = \%opt;

	bless( $self, $class );

	if ( not $opt{dont_touch_fs} ) {
		$self->sanity_check();
		$self->load_config();
		$self->load_defaults();
	}

	if ( $opt{master_password} ) {
		$self->get_master_password( $opt{master_password} );
	}

	return $self;
}

sub file_to_hash {
	my ( $self, $file ) = @_;
	my $ret;

	for my $line ( slurp($file) ) {
		my ( $key, $value ) = ( $line =~ m{ ^ ([^ ]+) \s+ (.+) $ }x );

		if ( not( $key and $value ) ) {
			next;
		}

		$ret->{$key} = $value;
	}
	return $ret;
}

sub sanity_check {
	my ($self) = @_;

	make_path( $self->{xdg_conf}, $self->{xdg_data} );

	if ( not -e $self->{xdg_conf} . '/password' ) {
		$self->create_config();
	}
	if ( not -e $self->{xdg_conf} . '/defaults' ) {
		$self->create_defaults();
	}

	return;
}

sub get_master_password {
	my ( $self, $pass ) = @_;

	if ( not defined $pass ) {
		$pass = $self->ui->read_pw( 'Master Password', 0 );
	}

	$self->{pass} = App::Raps2::Password->new(
		cost       => $self->{master_cost},
		salt       => $self->{master_salt},
		passphrase => $pass,
	);

	$self->pw->verify( $self->{master_hash} );

	return;
}

sub create_config {
	my ($self) = @_;

	my $cost = $self->{master_cost} = $self->{default}{cost} // 12;

	my $pass = $self->{default}{master_password} // $self->ui->read_pw(
		'Running for the first time. Please choose a master password', 1 );

	$self->{pass} = App::Raps2::Password->new(
		cost       => $self->{master_cost},
		passphrase => $pass,
	);

	my $hash = $self->{master_hash} = $self->pw->bcrypt;
	my $salt = $self->{master_salt} = $self->pw->salt;

	write_file(
		$self->{xdg_conf} . '/password',
		"cost ${cost}\n",
		"salt ${salt}\n",
		"hash ${hash}\n",
	);

	return;
}

sub load_config {
	my ($self) = @_;

	my $cfg = $self->file_to_hash( $self->{xdg_conf} . '/password' );

	$self->{master_hash} = $cfg->{hash};
	$self->{master_salt} = $cfg->{salt};
	$self->{master_cost} = $cfg->{cost};

	return;
}

sub create_defaults {
	my ($self) = @_;

	my $cost      = $self->{default}{cost}      // 12;
	my $pwgen_cmd = $self->{default}{pwgen_cmd} // 'pwgen -s 23 1';
	my $xclip_cmd = $self->{default}{xclip_cmd} // 'xclip -l 1';

	write_file(
		$self->{xdg_conf} . '/defaults',
		"cost = ${cost}\n",
		"pwgen_cmd = ${pwgen_cmd}\n",
		"xclip_cmd = ${xclip_cmd}\n",
	);

	return;
}

sub load_defaults {
	my ($self) = @_;

	my $cfg = Config::Tiny->read( $self->{xdg_conf} . '/defaults' );

	$self->{default}{cost}      //= $cfg->{_}->{cost};
	$self->{default}{pwgen_cmd} //= $cfg->{_}->{pwgen_cmd};
	$self->{default}{xclip_cmd} //= $cfg->{_}->{xclip_cmd};

	return;
}

sub conf {
	my ( $self, $key ) = @_;

	return $self->{default}{$key};
}

sub pw {
	my ($self) = @_;

	if ( defined $self->{pass} ) {
		return $self->{pass};
	}
	else {
		confess(
			'No App::Raps2::Password object, did you call get_master_password?'
		);
	}

	return;
}

sub ui {
	my ($self) = @_;

	return $self->{ui};
}

sub generate_password {
	my ($self) = @_;

	open( my $pwgen, q{-|}, $self->conf('pwgen_cmd') ) or return;
	my $password = ( split( / /, <$pwgen> ) )[0];
	close($pwgen) or cluck("Cannot close pwgen pipe: $!");

	chomp $password;

	return $password;
}

sub pw_save {
	my ( $self, %data ) = @_;

	$data{file}  //= $self->{xdg_data} . "/$data{name}";
	$data{login} //= q{};
	$data{salt}  //= $self->pw->create_salt();
	$data{url}   //= q{};
	$data{cost}  //= $self->{default}{cost};

	my $pass_hash = $self->pw->encrypt(
		data => $data{password},
		salt => $data{salt},
		cost => $data{cost},
	);
	my $extra_hash = (
		$data{extra}
		? $self->pw->encrypt(
			data => $data{extra},
			salt => $data{salt},
			cost => $data{cost},
		  )
		: q{}
	);

	write_file(
		$data{file},
		"url $data{url}\n",
		"login $data{login}\n",
		"cost $data{cost}\n",
		"salt $data{salt}\n",
		"hash ${pass_hash}\n",
		"extra ${extra_hash}\n",
	);

	return;
}

sub pw_load {
	my ( $self, %data ) = @_;

	$data{file} //= $self->{xdg_data} . "/$data{name}";

	my $key = $self->file_to_hash( $data{file} );

	# $self->{default}{cost} is the normal way, but older password files
	# (created before the custom cost support) do not have a cost field and
	# use the one of the master password

	return {
		url      => $key->{url},
		login    => $key->{login},
		cost     => $key->{cost} // $self->{master_cost},
		password => $self->pw->decrypt(
			data => $key->{hash},
			salt => $key->{salt},
			cost => $key->{cost} // $self->{master_cost},
		),
		salt  => $key->{salt},
		extra => (
			$key->{extra}
			? $self->pw->decrypt(
				data => $key->{extra},
				salt => $key->{salt},
				cost => $key->{cost} // $self->{master_cost},
			  )
			: undef
		),
	};
}

sub pw_load_info {
	my ( $self, %data ) = @_;

	$data{file} //= $self->{xdg_data} . "/$data{name}";

	my $key = $self->file_to_hash( $data{file} );

	return {
		url   => $key->{url},
		login => $key->{login},
		salt  => $key->{salt},
		cost  => $key->{cost},
	};
}

1;

__END__

=head1 NAME

App::Raps2 - A Password safe

=head1 SYNOPSIS

    use App::Raps2;

    my $raps2 = App::Raps2->new();

=head1 DESCRIPTION

B<App::Raps2> is the backend for B<raps2>, a simple commandline password safe.

=head1 VERSION

This manual documents App::Raps2 version 0.54

=head1 METHODS

=over

=item $raps2 = App::Raps2->new( I<%conf> )

Returns a new B<App::Raps2> object.

Accepted configuration parameters are:

=over

=item B<cost> => I<int>

B<cost> of key setup, passed on to App::Raps2::Password(3pm).

Default: 12

=item B<no_cli> => I<bool>

If set to true, App::Raps2 assumes it will not be used as a CLI. It won't
initialize its Term::ReadLine object and won't try to read anything from the
terminal.

=item B<pwgen_cmd> => I<comand>

Command to use in B<generate_password>.

Default: pwgen -s 23 1

=back

Note that the B<cost> and B<pwgen_cmd> options specified here take precedence
over those loaded from the config file.

=item $raps2->get_master_password( [I<$password>] )

Sets the master password used to encrypt all accounts. Uses I<password> if
specified, otherwise it asks the user via App::Raps2::UI(3pm).

=item $raps2->pw_load( B<file> => I<file> | B<name> => I<name> )

Load a password from I<file> (or account I<name>), requires
B<get_master_password> to have been called before.

Returns a hashref containing its url, login, salt, cost and decrypted password
and extra.

=item $raps2->pw_load_info( B<file> => I<file> | B<name> => I<name> )

Load all unencrypted data from I<file> (or account I<name>). Unlike
B<pw_load>, this method does not require a prior call to
B<get_master_password>.

Returns a hashref with url, login, salt and cost.

=item $raps2->pw_save( I<%data> )

Write an account as specified by I<data> to the store. Requires
B<get_master_password> to have been called before.

The following I<data> keys are supported:

=over

=item B<password> => I<password to encrypt> (mandatory)

=item B<salt> => I<salt>

=item B<cost> => I<cost> (optional, inferred from B<new> / the config otherwise)

=item B<file> => I<file> | B<name> => I<name> (one must be set)

=item B<url> => I<url> (optional)

=item B<login> => I<login> (optional)

=item B<extra> => I<extra> (optiona)

=back

=item $raps2->ui()

Returns the App::Raps2::UI(3pm) object.

=item $raps2->conf(I<key>)

Returns the current config value of I<key>, either set by B<new> or loaded
from the defaults config file.

=item $raps2->generate_password()

Runs B<pwgen_cmd> (as specified in B<new> or the config file) and returns its
first word of output, without trailing newlines / whitespaces.

=back

=head2 INTERNAL

You usually don't need to call these methods by yourself.

=over

=item $raps2->create_config()

Creates a password file and asks the user to set a master password.

=item $raps2->load_config()

Load config. Automatically called by B<new>.

=item $raps2->create_defaults()

Creates a defaults config file containing the default key setup cost and pwgen
command.

=item $raps2->load_defaults()

Loads the defaults file. Automatically called by B<new>.

=item $raps2->pw()

Returns the App::Raps2::Password(3pm) object.

=item $raps2->file_to_hash( I<$file> )

Reads $file (lines with key/value separated by whitespace) and returns a
hashref with its key/value pairs.

=item $raps2->sanity_check()

Create working directories (~/.config/raps2 and ~/.local/share/raps2, or the
respective XDG environment variable contents), if they don't exist yet.
Automatically called by B<new>.

Calls B<create_config> and B<create_defaults> if no configs were found.

=back

=head1 DIAGNOSTICS

If anything goes wrong, B<App::Raps2> will die with a backtrace (using
B<confess> from Carp(3pm)).

=head1 DEPENDENCIES

App::Raps2::Password(3pm), App::Raps2::UI(3pm), File::BaseDir(3pm),
File::Slurp(3pm).

=head1 BUGS AND LIMITATIONS

Be aware that the password handling API is not yet stable.
Also, so far the development concentrated on B<raps2>, so this module / its
documentation may not be completely up-to-date.

=head1 AUTHOR

Copyright (C) 2011-2015 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
