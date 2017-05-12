NAME
       CGI::FormBuilder::Mail::FormatMultiPart

       Plugin for CGI::FormBuilder->mailresults()

SYNOPSIS
           use CGI::FormBuilder;

           my $form = CGI::FormBuilder->new(
               ...
               # see CGI::FormBuilder manpage
           );

           if ($form->submitted && $form->validate) {
               $form->mailresults(
                   plugin          => 'FormatMultiPart',
                   from            => $from_address,
                   to              => $to_address,
                   cc              => $cc_address_or_comma_sep_scalar,
                   bcc             => $bcc_address_or_comma_sep_scalar,
                   smtp            => $smtp_host_or_ip,
                   subject         => 'subject',           # optional
                   skipfields      => ['field1','field2'], # optional
                   format          => 'plain', # or 'html' or 'both'
                   html_qt_format  => { },     # HTML::QuickTable args
                   css             => $css,    # scalar in-line css
               );
           }

DESCRIPTION
       A plugin for CGI::FormBuilder to prettily send the form submission via
       e-mail, without requiring the presence of sendmail on the system or
       using a shell escape (i.e. Windows).  It uses MIME::Lite to build the
       message and that module's interface to Net::SMTP to send it.

       Default message format is 'plain' but you can specify 'html' or 'both',
       which results in a multipart message.  (Not sure if I have that right
       yet.)

       If HTML, can pass a stylesheet that is printed in-line, as well as
       arguments to HTML::QuickTable.  ('header' is ignored.)  The default
       style class is 'fb_mail' for all elements.  You can use a partial CSS
       spec to override this class's styles; defaults will otherwise still
       apply.

       Will attach all file uploads as multipart MIME attachments.  The file
       names are listed in the form data table.

       If it cannot be used, it will puke a warning message and die.

WRITING YOUR OWN PLUGIN
       This establishes a simple mail plugin implementation standard for your
       own mailresults() plugins.  The plugin should reside under the
       CGI::FormBuilder::Mail::* namespace.  It should have a constructor
       new() which accepts a hash-as-array of named arg parameters, including
       form => $form.  It should have a mailresults() object method that does
       the right thing.  It should use CGI::FormBuilder::Util and puke() if
       something goes wrong.

       Calling $form->mailresults( plugin => 'Foo', ... ) will use CGI::Form-
       Builder::Mail::Foo and will pass the FormBuilder object as a named
       param 'form' with all other parameters passed intact.

       If it should croak, confess, die or otherwise break if something goes
       wrong, FormBuilder.pm will warn any errors and the built-in mailre-
       sults() method will still try.

BUGS
       Styles don't do anything in my copy of Evolution, at least.  But they
       do have the intended effect in Mozilla Mailnews, so I guess it's good
       to go.

DEPENDENCIES
       MIME::Types, Net::SMTP, MIME::Lite, Text::FormatTable, HTML::Quick-
       Table, "CGI::FormBuilder version 3.0301 or higher"

SEE ALSO
       CGI::FormBuilder, MIME::Lite, Text::FormatTable, HTML::QuickTable

AUTHOR
       Copyright (c) 2006 Mark Hedges <hedges@ucsd.edu>.

       This module is free software; you may copy this under the terms of the
       GNU General Public License, or the Artistic License, copies of which
       should have accompanied your Perl kit.
