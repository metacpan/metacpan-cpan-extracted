package Anansi::Actor;


=head1 NAME

Anansi::Actor - A dynamic usage module definition

=head1 SYNOPSIS

    use Anansi::Actor;
    my $object = Anansi::Actor->new(
        PACKAGE => 'Anansi::Example',
    );
    $object->someSubroutine() if(defined($object));

    use Anansi::Actor;
    use Data::Dumper qw(Dumper);
    my %modules = Anansi::Actor->modules();
    if(defined($modules{DBI})) {
        Anansi::Actor->new(
            PACKAGE => 'DBI',
        );
        print Data::Dumper::Dumper(DBI->available_drivers());
    }

    use Anansi::Actor;
    use Data::Dumper qw(Dumper);
    if(1 == Anansi::Actor->modules(
        PACKAGE => 'DBI',
    )) {
        Anansi::Actor->new(
            PACKAGE => 'DBI',
        );
        print Data::Dumper::Dumper(DBI->available_drivers());
    }

=head1 DESCRIPTION

This is a dynamic usage module definition that manages the loading of a required
namespace and blessing of an object of the namespace as required.  Uses L<Fcntl>,
L<File::Find>, L<File::Spec::Functions> and L<FileHandle>.

=cut


our $VERSION = '0.14';

use base qw(Anansi::Singleton);

use Fcntl ':flock';
use File::Find;
use File::Spec::Functions;
use FileHandle;


my $ACTOR = Anansi::Actor->SUPER::new();


=head1 METHODS

=cut


=head2 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of L<Anansi::Singleton|Anansi::Singleton>.

=cut


=head3 DESTROY

See L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY"> for details.  Overridden by L<Anansi::Singleton::DESTROY|Anansi::Singleton/"DESTROY">.

=cut


=head3 finalise

See L<Anansi::Class::finalise|Anansi::Class/"finalise"> for details.  A virtual method.

=cut


=head3 implicate

See L<Anansi::Class::implicate|Anansi::Class/"implicate"> for details.  A virtual method.

=cut


=head3 import

See L<Anansi::Class::import|Anansi::Class/"import"> for details.

=cut


=head3 initialise

See L<Anansi::Class::initialise|Anansi::Class/"initialise"> for details.  A virtual method.

=cut


=head3 new

See L<Anansi::Class::new|Anansi::Class/"new"> for details.  Overridden by L<Anansi::Singleton::new|Anansi::Singleton/"new">.

=cut


=head3 old

See L<Anansi::Class::old|Anansi::Class/"old"> for details.

=cut


=head3 used

See L<Anansi::Class::used|Anansi::Class/"used"> for details.

=cut


=head3 uses

See L<Anansi::Class::uses|Anansi::Class/"uses"> for details.

=cut


=head3 using

See L<Anansi::Class::using|Anansi::Class/"using"> for details.

=cut


=head2 Anansi::Singleton

See L<Anansi::Singleton|Anansi::Singleton> for details.  A parent module of L<Anansi::Actor|Anansi::Actor>.

=cut


=head3 Anansi::Class

See L<Anansi::Class|Anansi::Singleton> for Class.  A parent module of L<Anansi::Singleton|Anansi::Singleton>.

=cut


=head3 DESTROY

See L<Anansi::Singleton::DESTROY|Anansi::Singleton/"DESTROY"> for details.  Overrides L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY">.

=cut


=head3 fixate

See L<Anansi::Singleton::fixate|Anansi::Singleton/"fixate"> for details.  A virtual method.

=cut


=head3 new

See L<Anansi::Singleton::new|Anansi::Singleton/"new"> for details.  Overrides L<Anansi::Class::new|Anansi::Class/"new">.  Overridden by L<Anansi::Actor::new|Anansi::Actor/"new">.

=cut


=head3 reinitialise

See L<Anansi::Singleton::reinitialise|Anansi::Singleton/"reinitialise"> for details.  A virtual method.

=cut


=head2 modules

    my %MODULES = $object->modules();

    use Anansi::Actor;
    my %MODULES = Anansi::Actor->modules(
        INTERVAL => 3600,
    );

    if(1 == $object->modules(
        PACKAGE => [
            'Some::Module::Namespace',
            'Another::Module::Namespace',
            'Yet::Another::Module::Namespace'
        ],
    )) {
        print 'The modules have been found.'."\n";
    }

    use Anansi::Actor;
    my $MODULE = 'Some::Module::Namespace';
    if(0 == Anansi::Actor->modules(
        PACKAGE => $MODULE,
        INTERVAL => 43200,
    )) {
        print 'The "'.$MODULE.'" module has not been found.'."\n";
    }

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item parameters I<(Hash)>

Named parameters.

=over 4

=item INTERVAL I<(String, Optional)>

Specifies a refresh interval in seconds.  Defaults to 86400 seconds (1 day).

=item PACKAGE I<(Array B<or> String, Optional)>

An ARRAY of module namespaces or a module namespace to find on the operating
system.

=back

=back

Builds a HASH of all the modules and their paths that are available on the
operating system and either returns the module HASH or a B<1> I<(one)> on
success and a B<0> I<(zero)> on failure when determining the existence of the
modules that are specified in the I<PACKAGE> parameter.  A temporary file
"Anansi-Actor.#" will be created if at all possible to improve the speed of this
subroutine by storing the module HASH.  The temporary file will automatically
be updated when this subroutine is subsequently run when the number of seconds
specified in the I<INTERVAL> parameter or a full day has passed.  Deleting the
temporary file will also cause an update to occur.

=cut


sub modules {
    my ($self, %parameters) = @_;
    if(defined($parameters{PACKAGE})) {
        $parameters{PACKAGE} = [($parameters{PACKAGE})] if(ref($parameters{PACKAGE}) =~ /^$/);
        return 0 if(ref($parameters{PACKAGE}) !~ /^ARRAY$/i);
        return 0 if(0 == scalar(@{$parameters{PACKAGE}}));
        foreach my $package (@{$parameters{PACKAGE}}) {
            return 0 if(ref($package) !~ /^$/);
            return 0 if($package !~ /^[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)*$/);
        }
    }
    $ACTOR->{INTERVAL} = 86400 if(!defined($ACTOR->{INTERVAL}));
    if(!defined($parameters{INTERVAL})) {
    } elsif(ref($parameters{INTERVAL}) !~ /^$/) {
    } elsif($parameters{INTERVAL} !~ /^\s*[\-+]?\d+\s*$/) {
    } elsif(0 + $parameters{INTERVAL} <= 0) {
    } else {
        $ACTOR->{INTERVAL} = 0 + $parameters{INTERVAL};
    }
    my $TIMESTAMP = time();
    my $filename;
    my $refresh = 0;
    my $update = 0;
    if(opendir(DIRECTORY, File::Spec->tmpdir())) {
        my @files = reverse(sort(grep(/^Anansi-Actor\.\d+$/, readdir(DIRECTORY))));
        closedir(DIRECTORY);
        $filename = 'Anansi-Actor.'.$TIMESTAMP;
        if(0 < scalar(@files)) {
            my $timestamp = (split(/\./, $files[0]))[1];
            if(!defined($ACTOR->{TIMESTAMP})) {
                if(0 + $TIMESTAMP < 0 + $timestamp + $ACTOR->{INTERVAL}) {
                    $filename = shift(@files);
                    $ACTOR->{TIMESTAMP} = 0 + $timestamp;
                    $refresh = 1;
                } else {
                    $ACTOR->{TIMESTAMP} = 0 + $TIMESTAMP;
                    $update = 1;
                }
            } elsif(0 + $TIMESTAMP < 0 + $ACTOR->{TIMESTAMP} + $ACTOR->{INTERVAL}) {
                if(0 + $ACTOR->{TIMESTAMP} <= 0 + $timestamp) {
                    $filename = shift(@files);
                    $ACTOR->{TIMESTAMP} = 0 + $timestamp;
                    $refresh = 1;
                } else {
                    $filename = 'Anansi-Actor.'.$ACTOR->{TIMESTAMP};
                }
            } else {
                $ACTOR->{TIMESTAMP} = 0 + $TIMESTAMP;
                $update = 1;
            }
            foreach my $file (@files) {
                $file = File::Spec->catfile(File::Spec->splitdir(File::Spec->tmpdir()), $file);
                unlink($file);
            }
        }
        $filename = File::Spec->catfile(File::Spec->splitdir(File::Spec->tmpdir()), $filename);
        $refresh = 1 if(!defined($ACTOR->{MODULES}));
        if($refresh) {
            if(open(FILE_HANDLE, '<'.$filename)) {
                flock(FILE_HANDLE, LOCK_EX);
                my @contents = <FILE_HANDLE>;
                my $content = join(',', @contents);
                flock(FILE_HANDLE, LOCK_UN);
                close(FILE_HANDLE);
                %{$ACTOR->{MODULES}} = split(',', $content);
            } else {
                $update = 1;
            }
        }
    } elsif(!defined($ACTOR->{TIMESTAMP})) {
        $ACTOR->{TIMESTAMP} = $TIMESTAMP;
        $update = 1;
    } elsif(0 + $ACTOR->{TIMESTAMP} + $ACTOR->{INTERVAL} < 0 + $TIMESTAMP) {
        $ACTOR->{TIMESTAMP} = $TIMESTAMP;
        $update = 1;
    }
    if($update) {
        $ACTOR->{MODULES} = {};
        File::Find::find(
            {
                wanted => sub {
                    my $path = File::Spec->canonpath($_);
                    return if($path !~ /\.pm$/);
                    return if(!open(FILE, $path));
                    my $package;
                    my $pod = 0;
                    while(<FILE>) {
                        chomp;
                        if(/^=cut.*$/) {
                            $pod = 0;
                            next;
                        }
                        $pod = 1 if(/^=[a-zA-Z]+.*$/);
                        next if($pod);
                        next if($_ !~ /^\s*package\s+[a-zA-Z0-9_:]+\s*;.*$/);
                        ($package = $_) =~ s/^\s*package\s+([a-zA-Z0-9_:]+)\s*;.*$/$1/;
                    }
                    close(FILE);
                    return if(!defined($package));
                    return if(defined(${$ACTOR->{MODULES}}{$package}));
                    ${$ACTOR->{MODULES}}{$package} = $path;
                },
                follow => 1,
                follow_skip => 2,
                no_chdir => 1,
            },
            @INC
        );
    }
    if(defined($filename)) {
        if(open(FILE_HANDLE, '<'.$filename)) {
            close(FILE_HANDLE);
        } else {
            my $content = join(',', @{[%{$ACTOR->{MODULES}}]});
            if(open(FILE_HANDLE, '+>'.$filename)) {
                FILE_HANDLE->autoflush(1);
                flock(FILE_HANDLE, LOCK_EX);
                print FILE_HANDLE $content;
                flock(FILE_HANDLE, LOCK_UN);
                close(FILE_HANDLE);
            }
        }
    }
    if(defined($parameters{PACKAGE})) {
        foreach my $package (@{$parameters{PACKAGE}}) {
            return 0 if(!defined(${$ACTOR->{MODULES}}{$package}));
        }
        return 1;
    }
    return %{$ACTOR->{MODULES}};
}


=head2 new

    my $object = Anansi::Actor->new(
        PACKAGE => 'Anansi::Example',
    );

=over 4

=item class I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item parameters I<(Hash)>

Named parameters.

=over 4

=item BLESS I<(String, Optional)>

The name of the subroutine within the namespace that creates a blessed object of
the namespace.  Defaults to I<"new">.

=item IMPORT I<(Array, Optional)>

An array of the names to import from the loading module.

=item PACKAGE I<(String, Required)>

The namespace of the module to load.

=item PARAMETERS I<(Array B<or> Hash, Optional)>

Either An array or a hash of the parameters to pass to the blessing subroutine.

=back

=back

Overrides I<(L<Anansi::Singleton::new|Anansi::Singleton/"new">)>.  Instantiates
an object instance of a dynamically loaded module.

=cut


sub new {
    my ($class, %parameters) = @_;
    return if(!defined($parameters{PACKAGE}));
    return if(ref($parameters{PACKAGE}) !~ /^$/);
    return if($parameters{PACKAGE} !~ /^[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)*$/);
    if(!defined($parameters{BLESS})) {
        $parameters{BLESS} = 'new';
    } else {
        return if(ref($parameters{BLESS}) !~ /^$/);
        return if($parameters{BLESS} !~ /^[a-zA-Z]+[a-zA-Z0-9_]*$/);
    }
    if(defined($parameters{PARAMETERS})) {
        $parameters{PARAMETERS} = [(%{$parameters{PARAMETERS}})] if(ref($parameters{PARAMETERS}) =~ /^HASH$/i);
        return if(ref($parameters{PARAMETERS}) !~ /^ARRAY$/i);
    }
    if(defined($parameters{IMPORT})) {
        return if(ref($parameters{IMPORT}) !~ /^ARRAY$/i);
        foreach my $import (@{$parameters{IMPORT}}) {
            return if(ref($import) !~ /^$/);
            return if($import !~ /^[a-zA-Z_]+[a-zA-Z0-9_]*$/);
        }
    }
    my $package = $parameters{PACKAGE};
    my $bless = $parameters{BLESS};
    my $self;
    eval {
        (my $file = $package) =~ s/::/\//g;
        require $file.'.pm';
        if(defined($parameters{IMPORT})) {
            $package->import(@{$parameters{IMPORT}});
        } else {
            $package->import();
        }
        if(defined($parameters{PARAMETERS})) {
            $self = $package->$bless(@{$parameters{PARAMETERS}});
        } else {
            $self = $package->$bless();
        }
        1;
    } or do {
        my $error = $@;
        return ;
    };
    return $self;
}


=head1 NOTES

This module is designed to make it simple, easy and quite fast to code your
design in perl.  If for any reason you feel that it doesn't achieve these goals
then please let me know.  I am here to help.  All constructive criticisms are
also welcomed.

=cut


=head1 AUTHOR

Kevin Treleaven <kevin I<AT> treleaven I<DOT> net>

=cut


1;
