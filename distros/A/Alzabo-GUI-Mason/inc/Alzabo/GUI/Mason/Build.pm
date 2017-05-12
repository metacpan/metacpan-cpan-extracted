package Alzabo::GUI::Mason::Build;

use strict;

use lib './lib', './blib';

use Module::Build 0.16;
use base 'Module::Build';

use Cwd;
use Data::Dumper;
use File::Path;
use File::Spec;

sub ACTION_install
{
    my $self = shift;

    $self->SUPER::ACTION_install;

    $self->depends_on('install_components');
}

sub ACTION_install_components
{
    my $self = shift;

    $self->_make_mason_dirs( 'schema' );

    require Alzabo::GUI::Mason::Config;
    my $base = Alzabo::GUI::Mason::Config::mason_web_dir();
    my $count = $self->_copy_dir( [ cwd(), 'mason' ],
                                  [ $base, 'schema' ] );
    if ($count)
    {
	warn <<'EOF';

Finished installing mason based schema creation interface.

EOF
    }
    else
    {
	warn <<'EOF';

No changes in mason based schema creation interface components.  No
files copied.

EOF
    }
}

sub _make_mason_dirs
{
    my $self = shift;

    $self->_get_uid_gid;

    require Alzabo::GUI::Mason::Config;
    my $base = Alzabo::GUI::Mason::Config::mason_web_dir();

    foreach (@_)
    {
        my $dir = File::Spec->catdir( $base, $_ );
	unless ( -d $dir )
	{
	    mkpath( $dir, 1, 0755 )
		or die "Can't make $dir dir: $!\n";
	    warn "chown $dir to $self->{Alzabo}{user}/$self->{Alzabo}{group}\n";
	    chown $self->{Alzabo}{uid}, $self->{Alzabo}{gid}, $dir
		or die "Can't chown $dir to $self->{Alzabo}{user}/$self->{Alzabo}{group}: $!\n?";
	}
    }
}

sub _copy_dir
{
    my ( $self, $f, $t ) = @_;

    $self->_get_uid_gid;

    my $dh = do { local $^W = 0; local *DH; local *DH; };

    my $from = File::Spec->catdir(@$f);
    my $to   = File::Spec->catdir(@$t);

    opendir $dh, $from
	or die "Can't read $from dir: $!\n";

    my $ext = Alzabo::GUI::Mason::Config::mason_extension();

    my $count = 0;
    foreach my $from_f ( grep { ( ! /~\Z/ ) &&
                                -f File::Spec->catfile( $from, $_ ) }
                         readdir $dh )
    {
        my $to_f = File::Spec->catfile( $to, $from_f );
        $to_f =~ s/\.mhtml$/$ext/;

        my $target =
            $self->copy_if_modified( from => File::Spec->catfile( $from, $from_f ),
                                     to   => $to_f,
                                   );

        # was up to date
        next unless $target;

        $count++;

	chown $self->{Alzabo}{uid}, $self->{Alzabo}{gid}, $target
	    or die "Can't chown $target to $self->{Alzabo}{user}/$self->{Alzabo}{group}: $!\n?";
    }

    closedir $dh;

    return $count;
}

sub _get_uid_gid
{
    my $self = shift;

    return if ( exists $self->{Alzabo}{uid} &&
                exists $self->{Alzabo}{gid} );

    $self->{Alzabo}{user} =
        $self->prompt( <<'EOF',

What user would you like to own the directories and files used for the
Mason components as well as the components themselves?
EOF
                       $self->_possible_web_user );

    $self->{Alzabo}{group} =
        $self->prompt( <<'EOF',

What group would you like to own the directories and files used for
the Mason components as well as the components themselves?
EOF
                       $self->_possible_web_group );

    $self->{Alzabo}{uid} = (getpwnam( $self->{Alzabo}{user} ))[2] || $<;
    $self->{Alzabo}{gid} = (getgrnam( $self->{Alzabo}{group} ))[2] || $(;
}

sub _possible_web_user
{
    foreach ( qw( www-data web apache daemon nobody root ) )
    {
	return $_ if getpwnam($_);
    }

    return (getpwuid( $< ))[0];
}

sub _possible_web_group
{
    foreach ( qw( www-data web apache nobody nogroup daemon root ) )
    {
	return $_ if getpwnam($_);
    }

    return (getgrgid( $( ))[0];
}


1;
