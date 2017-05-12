package Catalyst::Plugin::StackTrace;
use 5.008001;
use Moose;
with 'MooseX::Emulate::Class::Accessor::Fast';
use Devel::StackTrace;
use HTML::Entities;
use Scalar::Util qw/blessed/;
use MRO::Compat;
use namespace::autoclean;

our $VERSION = '0.12';

__PACKAGE__->mk_accessors('_stacktrace');

sub execute {
    my $c = shift;


    my $conf = $c->config->{stacktrace};

    return $c->next::method(@_) 
      unless defined $conf->{enable} && $conf->{enable}
          || !defined $conf->{enable} && $c->debug;

    local $SIG{__DIE__} = sub {
        my $error = shift;

        # ignore if the error is a Tree::Simple object
        # because FindByUID uses an internal die several times per request
        return if ( blessed($error) && $error->isa('Tree::Simple') );

        my $ignore_package = [ 'Catalyst::Plugin::StackTrace' ];
        my $ignore_class   = [];

        if ( $c->config->{stacktrace}->{verbose} < 2 ) {
            $ignore_package = [
                qw/
                   Catalyst
                   Catalyst::Action
                   Catalyst::Base
                   Catalyst::Dispatcher
                   Catalyst::Plugin::StackTrace
                   Catalyst::Plugin::Static::Simple
                   NEXT
                   Class::C3
                   main
                  /
            ];
            $ignore_class = [
                qw/
                   Catalyst::Engine
                  /
            ];
        }

        # Devel::StackTrace dies sometimes, and dying in $SIG{__DIE__} does bad
        # things
        my $trace;
        {
            local $@;
            eval {
                $trace = Devel::StackTrace->new(
                    ignore_package   => $ignore_package,
                    ignore_class     => $ignore_class,
                );
            };
        }
        die $error unless defined $trace;

        my @frames = $c->config->{stacktrace}->{reverse} ?
        reverse $trace->frames : $trace->frames;

        my $keep_frames = [];
        for my $frame ( @frames ) {
            # only display frames from the user's app unless verbose
            if ( !$c->config->{stacktrace}->{verbose} ) {
                my $app = "$c";
                $app =~ s/=.*//;
                next unless $frame->package =~ /^$app/;
            }

            push @{$keep_frames}, {
                pkg  => $frame->package,
                file => $frame->filename,
                line => $frame->line,
            };
        }
        $c->_stacktrace( $keep_frames );

        die $error;
    };

    return $c->next::method(@_);
}

sub finalize_error {
    my $c = shift;

    $c->next::method(@_);

    if ( $c->debug ) {
        return unless ref $c->_stacktrace eq 'ARRAY';

        # insert the stack trace into the error screen above the "infos" div
        my $html = qq{
            <style type="text/css">
                div.trace {
                    background-color: #eee;
                    border: 1px solid #575;
                }
                div#stacktrace table {
                    width: 100%;
                }
                div#stacktrace th, td {
                    padding-right: 1.5em;
                    text-align: left;
                }
                div#stacktrace .line {
                    color: #000;
                    font-weight: strong;
                }
            </style>
            <div class="trace error">
            <h2><a href="#" onclick="toggleDump('stacktrace'); return false">Stack Trace</a></h2>
                <div id="stacktrace">
                    <table>
                       <tr>
                           <th>Package</th>
                           <th>Line   </th>
                           <th>File   </th>
                       </tr>
        };
        for my $frame ( @{$c->_stacktrace} ) {

            # clean up the common filename of
            # .../MyApp/script/../lib/...
            if ( $frame->{file} =~ /../ ) {
                $frame->{file} =~ s{script/../}{};
            }

            my $pkg  = encode_entities $frame->{pkg};
            my $line = encode_entities $frame->{line};
            my $file = encode_entities $frame->{file};
            my $code_preview = _print_context(
                $frame->{file},
                $frame->{line},
                $c->config->{stacktrace}->{context}
            );

            $html .= qq{
                       <tr>
                           <td>$pkg</td>
                           <td>$line</td>
                           <td>$file</td>
                       </tr>
                       <tr>
                           <td colspan="3"><pre><p><code class="error">$code_preview</code></p></pre></td>
                       </tr>
            };
        }
        $html .= qq{
                    </table>
                </div>
            </div>
        };

        $c->res->{body} =~ s{<div class="infos">}{$html<div class="infos">};
    }
}

sub setup {
    my $c = shift;

    $c->next::method(@_);

    $c->config->{stacktrace}->{context} ||= 3;
    $c->config->{stacktrace}->{verbose} ||= 0;
}

sub _print_context {
    my ( $file, $linenum, $context ) = @_;

    my $code;
    if ( -f $file ) {
        my $start = $linenum - $context;
        my $end   = $linenum + $context;
        $start = $start < 1 ? 1 : $start;
        if ( my $fh = IO::File->new( $file, 'r' ) ) {
            my $cur_line = 0;
            while ( my $line = <$fh> ) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                my @tag = $cur_line == $linenum ? ('<strong class="line">', '</strong>') : (q{}, q{});
                $code .= sprintf(
                    '%s%5d: %s%s',
                        $tag[0],
                        $cur_line,
                        $line ? encode_entities $line : q{},
                        $tag[1],
                );
            }
        }
    }
    return $code;
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::StackTrace - Display a stack trace on the debug screen

=head1 SYNOPSIS

    use Catalyst qw/-Debug StackTrace/;

=head1 DESCRIPTION

This plugin will enhance the standard Catalyst debug screen by including
a stack trace of your appliation up to the point where the error occurred.
Each stack frame is displayed along with the package name, line number, file
name, and code context surrounding the line number.

This plugin is only active in -Debug mode by default, but can be enabled by
setting the C<enable> config option.

=head1 CONFIGURATION

Configuration is optional and is specified in MyApp->config->{stacktrace}.

=head2 enable

Allows you forcibly enable or disalbe this plugin, ignoring the current 
debug setting. If this option is defined, its value will be used.

=head2 context

The number of context lines of code to display on either side of the stack
frame line.  Defaults to 3.

=head2 reverse

By default, the stack frames are shown in from "top" to "bottom"
(newest to oldest). Enabling this option reverses the stack frames so they will
be displayed "bottom" to "top", or from the callers perspective.

=head2 verbose

This option sets the amount of stack frames you want to see in the stack
trace.  It defaults to 0, meaning only frames from your application's
namespace are shown.  You can use levels 1 and 2 for deeper debugging.

If set to 1, the stack trace will include frames from packages outside of
your application's namespace, but not from most of the Catalyst internals.
Packages ignored at this level include:

    Catalyst
    Catalyst::Action
    Catalyst::Base
    Catalyst::Dispatcher
    Catalyst::Engine::*
    Catalyst::Plugin::StackTrace
    Catalyst::Plugin::Static::Simple
    NEXT
    main

If set to 2, the stack trace will include frames from everything except this
module.

=head1 INTERNAL METHODS

The following methods are extended by this plugin.

=over 4

=item execute

In execute, we create a local die handler to generate the stack trace.

=item finalize_error

In finalize_error, we inject the stack trace HTML into the debug screen below
the error message.

=item setup

=back

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHORS

Andy Grundman, <andy@hybridized.org>

Matt S. Trout, <mst@shadowcatsystems.co.uk>

=head1 THANKS

The authors of L<CGI::Application::Plugin::DebugScreen>, from which a lot of
code was used.

=head1 COPYRIGHT

Copyright (c) 2005 - 2009
the Catalyst::Plugin::StackTrace L</AUTHORS>
as listed above.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
