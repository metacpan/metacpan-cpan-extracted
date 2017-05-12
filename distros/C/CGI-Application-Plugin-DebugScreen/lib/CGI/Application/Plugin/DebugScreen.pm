package CGI::Application::Plugin::DebugScreen;

use 5.006;
use strict;
use warnings;
use HTML::Template;
use Devel::StackTrace;
use IO::File;
use UNIVERSAL::require;

our $VERSION = '1.00';

our $A_CODE = '<a class="package" href="?rm=view_code&amp;module=';
our $A_POD  = '<a class="package" href="?rm=view_pod&amp;module=';
our $A_TAIL = '">';
our $A_END  = '</a>';

our $TEMPLATE = qq{
<html><!-- HTML::Template -->
   <head>
       <title>Error in <!-- TMPL_VAR NAME="title" --></title>
       <style type="text/css">
           body {
               font-family: "Bitstream Vera Sans", "Trebuchet MS", Verdana,
                           Tahoma, Arial, helvetica, sans-serif;
               color: #000;
               background-color: #E68200;
               margin: 0px;
               padding: 0px;
           }
           :link, :link:hover, :visited, :visited:hover {
               color: #000;
           }
           div.box {
               position: relative;
               background-color: #fff;
               border: 1px solid #aaa;
               padding: 4px;
               margin: 10px;
               -moz-border-radius: 10px;
           }
           div.infos {
               background-color: #fff;
               border: 3px solid #FFCC99;
               padding: 8px;
               margin: 4px;
               margin-bottom: 10px;
               -moz-border-radius: 10px;
               overflow: auto;
           }
           div.infos td.head{
               text-align: center;
           }

           h1 {
               margin: 0;
               color: #999999;
           }
           h2 {
               margin-top: 0;
               margin-bottom: 10px;
               font-size: medium;
               font-weight: bold;
               text-decoration: underline;
           }
           div.url {
               font-size: x-small;
               overflow: auto;
           }
           pre {
               font-size: .8em;
               line-height: 120%;
               font-family: 'Courier New', Courier, monospace;
               background-color: #FFCC99;
               color: #333;
               border: 1px dotted #000;
               padding: 5px;
               margin: 8px;
               overflow: auto;
           }
           pre b {
               font-weight: bold;
               color: #000;
               background-color: #E68200;
           }
           h1 a.package {
               color: #999999;
           }
       </style>
   </head>
   <body>
       <div class="box">
           <h1><!-- TMPL_VAR NAME="title_a" --></h1>

           <div class="url"><!-- TMPL_VAR NAME="url" --></div>
           <div class="infos">
               <!-- TMPL_VAR NAME="desc" --><br />
           </div>
           <div class="infos">
               <h2>StackTrace</h2>
               <table>

                   <tr>
                       <th>Package</th>
                       <th>Line   </th>
                       <th>File   </th>
                       <!-- TMPL_IF NAME="view" -->
                       <th>View   </th>
                       <!-- /TMPL_IF -->
                   </tr>
                   <!-- TMPL_LOOP NAME="stacktrace" -->
                       <tr>
                           <td class="head"><!-- TMPL_VAR NAME="package" --></td>

                           <td class="head"><!-- TMPL_VAR NAME="line" --></td>
                           <td class="head"><!-- TMPL_VAR NAME="filename" --></td>
                           <!-- TMPL_IF NAME="view" -->
                           <td class="head"><!-- TMPL_VAR NAME="code" --> <!-- TMPL_VAR NAME="pod" --></td>
                           <!-- /TMPL_IF -->
                       </tr>
                       <tr>
                           <td colspan="4"><pre><!-- TMPL_VAR NAME="code_preview" --></pre></td>
                       </tr>
                   <!-- /TMPL_LOOP -->
               </table>
           </div>
       </div>
   </body>
</html>
};

sub import {
    my $self   = shift;
    my $caller = scalar caller;

    $caller->add_callback( 'init', sub{
        my $self = shift;

        $SIG{__DIE__} = sub{
            push @{$self->{__stacktrace}},[Devel::StackTrace->new(ignore_package=>[qw/CGI::Application::Plugin::DebugScreen Carp CGI::Carp/])->frames];
            die @_; # rethrow
        };
        {
            no strict 'refs';
            *{"$caller\::report"} = \&debug_report;

            *{"$caller\::__debugscreen_error"} = sub{
                my $self = shift;
                if (
                      exists $INC{'CGI/Application/Plugin/ViewCode.pm'}
                      &&
                    ! exists $INC{'CGI/Application/Dispatch.pm'}
                   )
                {
                    $self->{__viewcode}++;
                }
                $self->report(@_);
            };
        }
    });

    $caller->add_callback( 'error', sub{
        my $self = shift;
        if ( $ENV{CGI_APP_DEBUG} && exists $INC{'CGI/Application/Plugin/ViewCode.pm'} ) {
            $self->error_mode('__debugscreen_error');
        }
    });

    if ( ! exists $INC{'CGI/Application/Plugin/ViewCode.pm'} ) {
        "CGI::Application::Plugin::ViewCode"->require
         or delete $INC{'CGI/Application/Plugin/ViewCode.pm'};
        unless ($@) {goto &CGI::Application::Plugin::ViewCode::import}
    }
}

sub debug_report{
    my $self = shift;
    my $desc = '' . shift; #stringify
                           #useful in case of exception from CGI::Application::Plugin::TT
    my $url = $self->query->url(-path_info=>1,-query=>1);

    my $title = ref $self || $self;

    $title = html_escape($title);
    my $title_a = $title;

    if ( $self->{__viewcode} ) {
        $title_a = $A_CODE . $title . $A_TAIL . $title . $A_END;
    }

    my $stacks = $self->{__stacktrace}[0];

    my @stacktraces;
    for my $stack ( @{$stacks} ) {
        my %s;
        $s{package}  = exists $stack->{pkg}  ? $stack->{pkg}  : $stack->{package};
        $s{filename} = exists $stack->{file} ? $stack->{file} : $stack->{filename};

        $s{package}  = html_escape($s{package});
        $s{filename} = html_escape($s{filename});
        $s{line}     = html_escape($stack->{line});
        $s{code_preview} = print_context($s{filename},$s{line},$s{package},$self->{__viewcode});

        if ( $self->{__viewcode} && $s{package} ne 'main' ) {
            $s{line}     = $A_CODE . $s{package} . '#'.$s{line} . $A_TAIL . $s{line} . $A_END;
            $s{pod}      = $A_POD  . $s{package} . $A_TAIL . 'pod'        . $A_END;
            $s{code}     = $A_CODE . $s{package} . $A_TAIL . 'code'       . $A_END;
            $s{filename} = $A_CODE . $s{package} . $A_TAIL . $s{filename} . $A_END;
            $s{package}  = $A_CODE . $s{package} . $A_TAIL . $s{package}  . $A_END;

            $s{view} = $self->{__viewcode};
        }
        push @stacktraces, \%s;
    }

    my $t = HTML::Template->new(
        scalarref => \$TEMPLATE,
        die_on_bad_params => 0,
    );
    $t->param(
        title   => $title,
        title_a => $title_a,
        view    => $self->{__viewcode},
        url     => html_escape($url),
        desc    => html_escape($desc),
        stacktrace => \@stacktraces,
    );

    $self->header_props( -type => 'text/html' );
    return $t->output;
}

sub print_context {
    my($file, $linenum, $package, $view) = @_;
    my $code;
    if (-f $file) {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ? 1 : $start;
        if (my $fh = IO::File->new($file, 'r')) {
            my $cur_line = 0;
            while (my $line = <$fh>) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                my @tag = $cur_line == $linenum ? qw(<b> </b>) : ("","");
                if ( $view && $package ne 'main' && $cur_line == $linenum ) {
                    my $t_line = $A_CODE.$package.'#'.$linenum.$A_TAIL;
                    $code .= sprintf(
                        '%s%s%5d: %s%s%s',
                            $tag[0], $t_line, $cur_line, html_escape($line), $A_END, $tag[1],
                    );
                }
                else {
                    $code .= sprintf(
                        '%s%5d: %s%s',
                            $tag[0], $cur_line, html_escape($line), $tag[1],
                    );
                }
            }
        }
    }
    return $code;
}

sub html_escape {
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;
    return $str;
}

1;

=head1 NAME

CGI::Application::Plugin::DebugScreen - add Debug support to CGI::Application.

=head1 VERSION

This documentation refers to CGI::Application::Plugin::DebugScreen version 0.06

=head1 SYNOPSIS

  use CGI::Application::Plugin::DebugScreen;

Only it.
If "Internal Server Error" was generated by "run_mode"....

=head1 DESCRIPTION

This plug-in add Debug support to CGI::Application.
This plug-in like Catalyst debug mode.

DebugScreen is done when B<$ENV{CGI_APP_DEBUG}> is set,
 and DebugScreen is not done when not setting it.
When your code is released, this plug-in need not be removed.

When 'die' is generated by 'run_mode',
 this plug-in outputs the stack trace by error_mode().
As for this plug-in, error_mode() is overwrited in error callback.
The error cannot be caught excluding run_mode.

This uses CGI::Application::Plugin::ViewCode
 if a state that CGI::Application::Plugin::ViewCode can be used or used.
But CGI::Application::Dispatch is used,
 this not uses CGI::Application::Plugin::ViewCode.

When CGI::Application::Plugin::ViewCode can be used,
 Title, Package, File, code and line are links to CGI::Application::Plugin::ViewCode's view_code mode.
line jumps to the specified line.
And pod are links to CGI::Application::Plugin::ViewCode's view_pod mode.
The code of the displayed is links to CGI::Application::Plugin::ViewCode's view_code mode.

=head1 DEPENDENCIES

L<strict>

L<warnings>

L<CGI::Application>

L<HTML::Template>

L<Devel::StackTrace>

L<IO::File>

L<CGI::Application::Plugin::ViewCode>

L<UNIVERSAL::require>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 SEE ALSO

L<CGI::Application::Plugin::ViewCode>

L<Sledge::Plugin::DebugScreen>

L<CGI::Carp::DebugScreen>

L<Catalyst::Plugin::StackTrace>

=head1 Thanks To

MATSUNO Tokuhiro (MATSUNO)

Koichi Taniguchi (TANIGUCHI)

Masahiro Nagano (KAZEBURO)

Tomoyuki Misonou

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut
