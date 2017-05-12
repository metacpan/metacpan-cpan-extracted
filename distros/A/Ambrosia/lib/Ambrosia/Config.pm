package Ambrosia::Config;
use strict;
use warnings;

use Data::Dumper;
use base qw/Exporter/;

use Ambrosia::error::Exceptions;
use Ambrosia::core::ClassFactory;

our $VERSION = 0.010;

our @EXPORT = qw/config/;

our %PROCESS_MAP = ();
our %CONFIGS = ();

sub import
{
    my $pkg = shift;
    my %prm = @_;
    assign($prm{assign}) if $prm{assign};

    __PACKAGE__->export_to_level(1, @EXPORT);
}

sub assign
{
    $PROCESS_MAP{$$} = shift;
}

sub new
{
    throw Ambrosia::error::Exception::BadUsage 'Cannot create object Config';
}

sub instance
{
    my $package = shift;
    my $key = shift;
    my $_config_data = shift;

    if ( $_config_data )
    {#start instance
        if ( ref $_config_data eq 'HASH' )
        {
            $CONFIGS{$key}->{CONFIG_HASH} = 1; #$_config_data;
        }
        elsif(!ref $_config_data)
        {
            $CONFIGS{$key}->{CONFIG_FILE} = $_config_data;
            $CONFIGS{$key}->{LAST_ACCESS} = (stat $_config_data )[9];
        }
        else
        {
            throw Ambrosia::error::BadParams 'Bad config params: ' . $_config_data;
        }
    }
    elsif ( $CONFIGS{$key}->{CONFIG_FILE} )
    {#Если конфиг сформирован и дата последней модификации файла не менялась вернем объект config
        my $last_access = (stat $CONFIGS{$key}->{CONFIG_FILE} )[9];

        return $CONFIGS{$key}->{OBJECT}
            if  defined $CONFIGS{$key}->{OBJECT}
                && defined $CONFIGS{$key}->{LAST_ACCESS}
                && $CONFIGS{$key}->{LAST_ACCESS} == $last_access;
        $CONFIGS{$key}->{LAST_ACCESS} = $last_access;
        $_config_data = $CONFIGS{$key}->{CONFIG_FILE};
    }
    elsif ( $CONFIGS{$key}->{CONFIG_HASH} )
    {#Если конфиг был сформирован на основе хэша - вернем объект
        return $CONFIGS{$key}->{OBJECT};
    }

    $package .= '_' . $key;
    $package =~ s/[^\w]+/_/g;
    $package =~ s|[\\\/]|::|g;

    $CONFIGS{$key}->{OBJECT} = $_config_data
        ? _create($package, $_config_data)
        : _error($package, $key);
    return $CONFIGS{$key}->{OBJECT};
}

sub config
{
    my $c = __PACKAGE__->instance(shift || $PROCESS_MAP{$$} || throw Ambrosia::error::Exception::BadUsage("First access to Ambrosia::Config without assign to config."));
    return $c;
}

sub _error
{
    my $package = shift;
    my $key = shift;

    my $ConfDump = '{';
    foreach ( keys %CONFIGS )
    {
        $ConfDump .= "\t$_ => $CONFIGS{$_}\n";
    }
    $ConfDump .= '}';

    warn "ErrorInConfig($$):\n\t\%CONFIGS=$ConfDump;\n\t" . ' %PROCESS_MAP=' . Dumper(\%PROCESS_MAP);
    throw Ambrosia::error::Exception::BadUsage("First access to Ambrosia::Config without create config object. [$package :: $key]")
}

sub _create
{
    my $package = shift;
    my $prm = shift;

    my $self;
    eval
    {
        my $conf = ref $prm eq 'HASH' ? $prm : ( do "$prm" or die($@ ? $@ : $!) );
        if ( ref $conf eq 'HASH' )
        {
            no strict 'refs';
            no warnings 'redefine';
            Ambrosia::core::ClassFactory::create($package, {public => [keys %$conf]});
            *{"$package\::DESTROY"} = sub {};
            ${"$package\::AUTOLOAD"} = '';
            *{"$package\::AUTOLOAD"} = sub : lvalue {
                my $this = shift;
                my $value = shift;
                my ($func) = our $AUTOLOAD =~ /(\w+)$/
                    or throw Ambrosia::error::Exception 'Error: cannot resolve AUTOLOAD: ' . $AUTOLOAD;
                *{$package . '::' . $func} = sub : lvalue { $_[0]->[1]->{$func} };
                $this->$func = $value;
            };

            $self = $package->new($conf);
        }
        elsif($conf)
        {
            die 'Bad config format in ' . $prm . '. Config file must return reference to hash.';
        }
    };
    if ( $@ )
    {
        throw Ambrosia::error::Exception('Error in config: ' . $prm . ';', $@);
    }
    return $self;
}

sub DESTROY
{
    
}

1;


__END__

=head1 NAME

Ambrosia::Config - a class for read a configuration data.
It implements the pattern B<Singleton>.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    #In the file "test.pl"
    use Ambrosia::Config;
    use Foo;
    BEGIN
    {
        instance Ambrosia::Config( myApplication => './foo.conf' );
    };
    Ambrosia::Config::assign 'myApplication';
    #..............
    say Foo::proc1();
    #..............

    #In the file "Foo.pm"
    package Foo;
    use Ambrosia::Config;

    sub proc1
    {
        return config->ParamA;
    }
    
    1;

    #In the config file "foo.conf"
    return { ParamA => 'ABC' };

=head1 DESCRIPTION

C<Ambrosia::Config> is a class of object Ambrosia::Config.
The file of config is the perl script that MUST return reference to hash.
Each key of the hash becomes a method of object of type Ambrosia::Config that return an appropriate value.

WARNING!
This method is "lvalue" and you can modify a config value on the fly.

=head2 instance

This method instantiates the named object of type C<Ambrosia::Config> in the pool.
This method not exported. Use as constructor: C<instance Ambrosia::Config(.....)>
C<instance(name =&gt; path)> - where the "name" is a keyname for config and the "path" is a path to config file.
C<instance(name =&gt; hash)> - where the "name" is a keyname for config and the "hash" is a config data.

=head2 config

Returns the global object of type C<Ambrosia::Config>.
C<config(name)> - the "name" is optional param. Call with "name" if you not assign current process to config.

=head2 assign ($name)

Assign current process to the global named object of type C<Ambrosia::Config>.

=head1 DEPENDENCIES

L<Ambrosia::core::Exceptions>
L<Ambrosia::Meta>

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
