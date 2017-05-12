package CGI::Application::Plugin::ViewCode;
use warnings;
use strict;

=head1 NAME

CGI::Application::Plugin::ViewCode - View the source of the running application

=cut

our $VERSION = '1.02';

# DEFAULT_STYLES taken from Apache::Syntax::Highlight::Perl by Enrico Sorcinelli
our %DEFAULT_STYLES = (
    'Comment_Normal'    => 'color:#006699;font-style:italic;',
    'Comment_POD'       => 'color:#001144;font-style:italic;',
    'Directive'         => 'color:#339999;font-style:italic;',
    'Label'             => 'color:#993399;font-style:italic;',
    'Quote'             => 'color:#0000aa;',
    'String'            => 'color:#0000aa;',
    'Subroutine'        => 'color:#998800;',
    'Variable_Scalar'   => 'color:#008800;',
    'Variable_Array'    => 'color:#ff7700;',
    'Variable_Hash'     => 'color:#8800ff;',
    'Variable_Typeglob' => 'color:#ff0033;',
    'Whitespace'        => 'white-space: pre;',
    'Character'         => 'color:#880000;',
    'Keyword'           => 'color:#000000;',
    'Builtin_Operator'  => 'color:#330000;',
    'Builtin_Function'  => 'color:#000011;',
    'Operator'          => 'color:#000000;',
    'Bareword'          => 'color:#33AA33;',
    'Package'           => 'color:#990000;',
    'Number'            => 'color:#ff00ff;',
    'Symbol'            => 'color:#000000;',
    'CodeTerm'          => 'color:#000000;',
    'DATA'              => 'color:#000000;',
    'LineNumber'        => 'color:#BBBBBB;'
);

our %SUBSTITUTIONS = (
    '<'     => '&lt;', 
    '>'     => '&gt;', 
    '&'     => '&amp;',
);

=head1 SYNOPSIS

In your CGI::Application based class

    use CGI::Application::Plugin::ViewCode;

Then you can view your module's source (or pod) as it's running by changing the url

    ?rm=view_code
    ?rm=view_code#215
    ?rm=view_code&pod=0&line_no=0
    ?rm=view_code&module=CGI-Application

    ?rm=view_pod
    ?rm=view_pod&module=CGI-Application

=head1 INTERFACE

This plugin works by adding extra run modes (named C<view_code> and C< view_pod >) to the
application. By calling this run mode you can see the source or POD of the running module
(by default) or you can specify which module you would like to view (see L<SECURITY>).


=head2 view_code

This extra run mode will accept the following arguments in the query string:

=over

=item module

The name of the module to view. By default it is the module currently being run. Also,
since colons (':') aren't simply typed into URL's, you can just substitute '-' for '::'.

    ?rm=view_code?module=My-Base-Class

=item highlight

Boolean indicates whether syntax highlighting (using L<Syntax::Highlight::Perl::Improved>) 
is C<on> or C<off>. By default it is C<on>.

=item line_no

Boolean indicates whether the viewing of line numbers is C<on> or C<off>. By default it is C<on>.
It C<line_no> is on, you can also specify which line number you want to see by adding an anchor
to the link:

    ?rm=view_code#215

This will take you immediately to line 215 of the current application module.

=item pod

Boolean indicates whether POD is seen or not. By default it is seen>.

=back


=head2 view_pod

This extra run mode will accept the following arguments in the query string:

=over

=item module

The name of the module to view. By default it is the module currently being run. Also,
since colons (':') aren't simply typed into URL's, you can just substitute '-' for '::'.

    ?rm=view_pod?module=My-Base-Class

=back

=head1 AS A POPUP WINDOW

This plugin can be used in conjunction with L<CGI::Application::Plugin::DevPopup>. If we detect
that L<CGI::Application::Plugin::DevPopup> is running and turned on, we will create a sub-report
that includes the highlighted source code.


So you can simply do the following:

    BEGIN { $ENV{CAP_DEVPOPUP_EXEC} = 1; } # turn it on for real
    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::ViewCode;

Befault, this report will be the same thing produced by C<view_code>. If you want this
report to include the C<view_pod> report, simply set the the C<$ENV{CAP_VIEWCODE_POPUP_POD}>
to true. You can also turn off the C<view_code> report but setting 
C<$ENV{CAP_VIEWCODE_POPUP_CODE}> to false.

    # have the POD report, but not the code in the dev popup window
    BEGIN { 
        $ENV{CAP_DEVPOPUP_EXEC} = 1;       # turn it on for real
        $ENV{CAP_VIEWCODE_POPUP_POD} = 1;  # turn on POD report
        $ENV{CAP_VIEWCODE_POPUP_CODE} = 0; # turn off code report
    }
    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::ViewCode;

=cut

sub import {
    my $caller = scalar(caller);
    $caller->add_callback( init => \&_add_runmode );

    # if we are running under CGI::Application::Plugin::DevPopup
    if( $ENV{CAP_DEVPOPUP_EXEC} ) {
        # if we wan't to add the POD report
        if( exists $ENV{CAP_VIEWCODE_POPUP_POD} && $ENV{CAP_VIEWCODE_POPUP_POD} ) {
            $caller->add_callback( devpopup_report => \&_view_pod );
        }
        # include the view_code report by default unless it's turned off
        if(! (exists $ENV{CAP_VIEWCODE_POPUP_CODE} && !$ENV{CAP_VIEWCODE_POPUP_CODE}) ) {
            $caller->add_callback( devpopup_report => \&_view_code );
        }
    }
}

sub _add_runmode {
    my $self = shift;
    $self->run_modes( 
        view_code => \&_view_code,
        view_pod  => \&_view_pod
    );
}

sub _view_code {
    my $self = shift;
    my $query = $self->query;

    my %options;
    foreach my $opt qw(highlight line_no pod) {
        if( defined $query->param($opt) ) {
            $options{$opt} = $query->param($opt);
        } else {
            $options{$opt} = 1;
        }
    }
        
    # get the file to be viewed
    my $module = _module_name($query->param('module') || ref($self));
    # change into file name
    my $file = _module_file_name($module);

    # make sure the file exists
    if( $file && -e $file ) {
        my $IN;
        open($IN, $file) 
            or return _error("Could not open $file for reading! $!");
        my @lines= <$IN>;

        # if we aren't going to highlight then turn all colors/styles
        # into simple black
        my %styles = %DEFAULT_STYLES;
        my $style_sec = '';
        foreach my $style (keys %styles) {
            $styles{$style} = 'color:#000000;'
                if( !$options{highlight} );
            $style_sec .= ".$style { $styles{$style} }\n";
        }

        # now use Syntax::Highlight::Perl::Improved to do the work
        require Syntax::Highlight::Perl::Improved;
        my $formatter = Syntax::Highlight::Perl::Improved->new();
        $formatter->define_substitution(%SUBSTITUTIONS);
        foreach my $style (keys %styles) {
            $formatter->set_format($style, [qq(<span class="$style">), qq(</span>)]);
        }
        @lines = $formatter->format_string(@lines);
        
        # if we want line numbers
        if( $options{line_no} ) {
            my $i = 1;
            @lines = map { 
                (qq(<span class="LineNumber"><a name="$i">) . $i++ . qq(:</a></span>&nbsp;). $_) 
            } @lines;
        }

        # apply any other transformations necessary
        if( $options{highlight} || !$options{pod} ) {
            foreach my $line (@lines) {
                # if they don't want the pod
                if( !$options{pod} ) {
                    if( $line =~ /<span class="Comment_POD"/ ) {
                        $line = '';
                        next;
                    }
                }
                
                # if they are highlighting
                if( $options{highlight} ) {
                    if( $line =~ /<span class="Package">([^<]*)<\/span>/ ) {
                        my $package = $1;
                        my $link = $package;
                        $link =~ s/::/-/g;
                        my $rm = $self->mode_param();
                        $rm = ref $rm ? 'rm' : $rm; # not really anything we can do if their mode_param returns a sub ref
                        $link = "?$rm=view_code&amp;module=$package;view_code_no_popup=1";
                        $line =~ s/<span class="Package">[^<]*<\/span>/<a class="Package" href="$link">$package<\/a>/;
                    }    
                }
            }
        }
        my $code = join('', @lines);

        # if we are under CGI::Application::Plugin::DevPopup then let's create this as a report instead
        if( $ENV{CAP_DEVPOPUP_EXEC} && !$query->param('view_code_no_popup') ) {
            $self->devpopup->add_report(
                title   => 'View Code',
                summary => "View code of $module", 
                report  => "<style>$style_sec</style><pre>$code</pre>",
            );
        } else {
            return qq(
            <html>
            <head>
                <title>$module - View Source</title>
                <style>$style_sec</style>
            </head>
            <body>
                <pre>$code</pre>
            </body>
            </html>
            );
        }
    } else {
        return _error( ($file ? "File $file " : "Module $module ") . "does not exist!");
    }
}

sub _view_pod {
    my $self = shift;
    my $query = $self->query;

    # get the file to be viewed
    my $module = _module_name($query->param('module') || ref($self));
    # change into file name
    my $file = _module_file_name($module);

    # make sure the file exists
    if( $file && -e $file ) {
        require Pod::Xhtml;
        my $pod_parser = new Pod::Xhtml(
            StringMode   => 1,
            MakeIndex    => 0,
            FragmentOnly => 1,
            TopLinks     => 0,
            MakeMeta     => 0,
        );
        $pod_parser->parse_from_file($file);
        my $pod = $pod_parser->asString;

        # if we are under CGI::Application::Plugin::DevPopup then let's create this as a report instead
        if( $ENV{CAP_DEVPOPUP_EXEC} && !$query->param('view_code_no_popup') ) {
            $self->devpopup->add_report(
                title   => 'View POD',
                summary => "View POD of $module", 
                report  => "<pre>$pod</pre>",
            );
        } else {
            return qq(
            <html>
            <head>
                <title>$module - View POD</title>
            </head>
            <body>
                <pre>$pod</pre>
            </body>
            </html>
            );
        }
    } else {
        return _error( ($file ? "File $file " : "Module $module ") . "does not exist!");
    }
}


sub _module_name {
    my $name = shift;
    $name =~ s/-/::/g;  
    return $name;
}

sub _module_file_name {
    my $module = shift;
    # change into file name
    $module =~ s/::/\//g;
    $module .= '.pm';
    return $INC{$module};
}


sub _error {
    my $message = shift;
    return qq(
    <html>
      <head>
        <title>View Source Error!</title>
      </head>
      <body>
        <h1 style="color: red">Error!</h1>
        <strong>Sorry, but there was an error in your 
        request to view the source: 
        <blockquote><em>$message</em></blockquote>
      </body>
    </html>
    );
}

1;

__END__

=head1 SECURITY

This plugin is designed to be used for development only. Please do not use it in a
production system as it will allow anyone to see the source code for any loaded module.
Consider yourself warned.

=head1 AUTHOR

Michael Peters, C<< <mpeters@plusthree.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-viewsource@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-ViewCode>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Peters, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

