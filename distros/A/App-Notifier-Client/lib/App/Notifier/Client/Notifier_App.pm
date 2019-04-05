package App::Notifier::Client::Notifier_App;
$App::Notifier::Client::Notifier_App::VERSION = '0.0301';
use strict;
use warnings;

use 5.012;

use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;

use YAML::XS qw( LoadFile );

use App::Notifier::Client;


sub new
{
    my $class = shift;
    my $self  = bless {}, $class;
    $self->_init(@_);
    return $self;
}

sub _argv
{
    my $self = shift;

    if (@_)
    {
        $self->{_argv} = shift;
    }

    return $self->{_argv};
}

sub _init
{
    my ( $self, $args ) = @_;

    $self->_argv( [ @{ $args->{argv} } ] );

    return;
}


sub run
{
    my ($self) = @_;

    my $argv = $self->_argv();

    my $op = shift(@$argv);

    if ( !defined($op) )
    {
        die "You did not specify any arguments - see --help";
    }

    if ( ( $op eq "-h" ) || ( $op eq "--help" ) )
    {
        pod2usage(1);
    }
    elsif ( $op eq "--man" )
    {
        pod2usage( -verbose => 2 );
    }

    if ( $op ne 'notify' )
    {
        die "Unknown operation - '$op'!";
    }

    my $help = 0;
    my $man  = 0;
    my ( $to, $url, $cmd_id, $msg );
    if (
        !(
            my $ret = GetOptionsFromArray(
                $argv,
                'help|h'  => \$help,
                man       => \$man,
                'to=s'    => \$to,
                'url=s'   => \$url,
                'cmd=s'   => \$cmd_id,
                'msg|m=s' => \$msg,
            )
        )
        )
    {
        die "GetOptions failed!";
    }

    if ($help)
    {
        pod2usage(1);
    }

    if ($man)
    {
        pod2usage( -verbose => 2 );
    }

    if ( !defined($url) )
    {
        if ( !defined($to) )
        {
            $to = 'default';
        }

        my $config_fn = ( $ENV{'NOTIFIER_CONFIG'}
                || File::Spec->catfile( $ENV{HOME}, '.app_notifier.yml' ) );

        my $config = LoadFile($config_fn);

        my $host_config = $config->{client}->{targets}->{$to};

        if ( !defined($host_config) )
        {
            die "Cannot find host config '$to' in $config_fn.";
        }

        $url = $host_config->{url};
    }

    if ( !defined($url) )
    {
        die "No URL specified - please specify one.";
    }

    App::Notifier::Client->notify(
        {
            base_url => $url,
            ( defined($cmd_id) ? ( cmd_id => $cmd_id ) : () ),
            ( defined($msg)    ? ( msg    => $msg )    : () ),
        }
    );

    return;
}


1;    # End of Module::Format::PerlMF_App

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Notifier::Client::Notifier_App

=head1 VERSION

version 0.0301

=head1 SYNOPSIS

    use strict;
    use warnings;

    use App::Notifier::Client::Notifier_App;

    App::Notifier::Client::Notifier_App->new({argv => [@ARGV],})->run();

=head1 NAME

App::Notifier::Client::Notifier_App - implements the notifier command-line
app.

=head1 VERSION

version 0.0301

=head1 FUNCTIONS

=head2 new({argv => [@ARGV]})

The constructor - call it with the command-line options.

=head2 run

Actually run the command line application.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 SEE ALSO

L<App::Notifier::Client>, L<App::Notifier::Service> .

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
