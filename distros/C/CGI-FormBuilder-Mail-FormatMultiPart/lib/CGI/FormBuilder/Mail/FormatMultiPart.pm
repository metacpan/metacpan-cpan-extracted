package CGI::FormBuilder::Mail::FormatMultiPart;

use strict;
use warnings;

our $VERSION = 1.000006;

use English '-no_match_vars;';

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field;

require MIME::Types;  # for MIME::Lite's AUTO type detection - required
require MIME::Lite;
require Text::FormatTable;
require HTML::QuickTable;

use Regexp::Common qw( net );

sub new {
    my $class = shift;
    my $self = { @_ };

    bless $self, $class;
    return $self;
}

sub mailresults {
    my ($self) = @_;

    # slice args into nicer var names, checking some params

    my $form = $self->{form};
    puke "No CGI::FormBuilder passed as form arg"
        if !$form || !$form->isa('CGI::FormBuilder');

    my ($subject, $to, $cc, $bcc, $from, $smtp )
        = @{$self}{qw( subject to cc bcc from smtp )};

    puke "Address/subject args should all be scalars"
        if scalar grep { defined && ref } 
            ( $to, $from, $smtp, $cc, $bcc, $subject );

    puke "Cannot send mail without to, from, and smtp args"
        if  !$to || !$from || !$smtp;
    
    puke "arg 'smtp' in bad format"
        if !(   $smtp eq 'localhost'
            ||  $smtp =~ m{ \A $RE{net}{domain}{-nospace} \z }xms
            ||  $smtp =~ m{ \A $RE{net}{IPv4} \z }xms
            )
        ;

    # let MIME::Lite check e-mail address or address list format 
    # (VALIDATE pattern for multiple addresses too much of a pain)

    my ($format, $skipfields, $skip ) = @{$self}{qw( format skipfields skip )};

    $format = $self->{format} = 'plain' if !$format;
    if  (   ref $format
        ||  !grep { $_ eq $format } qw( plain html both )
        ) {
       puke "Arg format should be 'plain', 'html', or 'both'.";
    }

    if ($skip || (defined $skipfields && ref $skipfields ne 'ARRAY')) {
        belch __PACKAGE__
            ." prefers arg 'skipfields' as arrayref, not skipping any";
        $skipfields = $self->{skipfields} = [ ];
    }

    # what's the default subject if not found?
    if (!$subject) {
        $self->{subject} = $subject 
            ||= sprintf $form->{messages}->mail_results_subject, $form->title;
    }

    # set up a hash of the individual CGI::FormBuilder::Field objects and
    # put it into $self to pass around.  it's useful.
    my $fbflds = $self->{_fbflds} = { map { ( "$_" => $_ ) } $form->field };

    # ok, now set up the e-mail

    my $parts = 1; # count parts to determine message type, args, construction
    $parts++ if $format eq 'both';

    my @file_attachments = $self->_file_attachments();
    #debug 1, "file_attachments: '@file_attachments'";

    $parts += scalar @file_attachments;

    #debug 1, "parts: '$parts'";

    my $msg = undef;
    my %msg_args = (
        From        => $from,
        To          => $to,
        Subject     => $subject,
        Type        => ($parts > 1) ? 'multipart/mixed' : "text/$format",
    );
    $msg_args{Cc}  = $cc       if defined $cc;
    $msg_args{Bcc} = $bcc      if defined $bcc;

    if ($parts == 1) {
        $msg_args{Data} = $self->_format_text();
        $msg = MIME::Lite->new( %msg_args );
    }
    else {
        $msg = MIME::Lite->new( %msg_args );
        if ($format eq 'plain' || $format eq 'both') {
            $msg->attach(
                Type        => 'TEXT',
                Data        => $self->_format_text_plain(),
            );
        }
        if ($format eq 'html' || $format eq 'both') {
            $msg->attach(
                Type        => 'text/html',
                Data        => $self->_format_text_html(),
            );
        }

        $msg->attach( %{$_} ) for @file_attachments;
    }

    my $success = eval $msg->send_by_smtp( $smtp );    

    if ($EVAL_ERROR || !$success) {
        puke("Could not send mail. $EVAL_ERROR");
    }

    return;
}

sub _format_text {
    # a simple dispatch
    my ($self) = @_;
    return ($self->{format} eq 'html')
        ? $self->_format_text_html()
        : $self->_format_text_plain();
}

sub _format_text_plain { 
    my ($self) = @_;

    my $text = $self->{subject}."\n\nForm Data:\n\n";

    my $fmt = '| l | l |';

    my $table_data = Text::FormatTable->new($fmt);
    my $data_form = $self->_data_form();
    $table_data->rule;
    $table_data->head( @{ $data_form->[0] } );
    $table_data->rule;

    # not sure yet if it's better to have rules between each var 
    do { $table_data->row( @{$_} ); $table_data->rule; }
        for @{$data_form}[ 1 .. $#{$data_form} ];

    #$table_data->row( @{$_} ) for @{$data_form}[ 1 .. $#{$data_form} ];
    #$table_data->rule;

    $text .= $table_data->render(72);

    my $data_files = $self->_data_files();
    if (defined $data_files) {
        $text .= "\n\nUploaded Files:\n\n";
        my $table_files = Text::FormatTable->new($fmt);
        $table_files->rule;
        $table_files->head( @{ $data_files->[0] } );
        $table_files->rule;
        $table_files->row( @{$_} ) for @{$data_files}[ 1 .. $#{$data_files} ];
        $table_files->rule;
        $text .= $table_files->render(72);
    }

    my $data_env = $self->_data_env();
    if (defined $data_env) {
        $text .= "\n\nBrowser/Connect Info:\n\n";
        my $table_env = Text::FormatTable->new($fmt);
        $table_env->rule;
        $table_env->head( @{ $data_env->[0] } );
        $table_env->rule;
        $table_env->row( @{$_} ) for @{$data_env}[ 1 .. $#{$data_env} ];
        $table_env->rule;
        $text .= $table_env->render(72);
    }

    $text .= "\n\nTime:\n\n";
    my $table_time = Text::FormatTable->new($fmt);
    my $data_time  = $self->_data_time();
    $table_time->rule;
    $table_time->head( @{ $data_time->[0] } );
    $table_time->rule;
    $table_time->row( @{$_} ) for @{$data_time}[ 1 .. $#{$data_time} ];
    $table_time->rule;
    $text .= $table_time->render(72);

    #print "<pre>\n$text\n</pre>\n";

    return $text;
}

sub _format_text_html {
    my ($self) = @_;

    my ($form, $fbflds, $skipfields, $subject, $css) 
        = @{$self}{qw( form _fbflds skipfields subject css )};

    my $fmt = $self->{html_qt_format};
    if ($fmt && ref $fmt ne 'HASH') {
        belch "html_qt_format is hashref for HTML::QuickTable. default used.";
        undef $fmt;
    }
    $fmt = { } if !$fmt;

    my $qt_real_fmt = {
        # all the defaults:
        cellspacing     => 0,
        cellpadding     => 0,
        border          => 0,
        labels          => 1,
        stylesheet      => 1,
        styleclass      => 'fb_mail',
        useid           => 'fb_mail',
        
        # or override with specified values:
        %{$fmt},

        # except no header, we never want to allow that:
        header          => 0,
    };

    my $base_css_class = $qt_real_fmt->{styleclass};
    my $default_css = <<END_CSS;
*.fb_mail {
    font-family:        Arial, Helvetica, sans-serif;
}
TABLE.fb_mail {
    padding:            0.5em;
    border:             1px solid black;
}
TD.fb_mail {
    font-face:          Arial, Helvetica, sans-serif;
    text-align:         left;
    vertical-align:     top;
    padding:            0.5em;
    background:         white;
    border:             1px dotted orange;
}
H1.fb_mail {
    color:              red;
}
END_CSS

    # their styles will override defaults, but defaults will still be used
    # if they don't make a full CSS spec for the table:
    $css = '' if !defined $css;
    $css = $default_css."\n".$css;  

    # OK, the only question is how to format CSS for e-mail so it will work.
    my $html = <<END_HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 TRANSITIONAL//EN">

<HTML>
<HEAD>

<STYLE type="text/css">
$css
</STYLE>

</HEAD>
<BODY>

<H1 CLASS="$base_css_class">$subject</H1>

END_HTML

    my $qt = HTML::QuickTable->new(
        %{$qt_real_fmt},
    );

    $html .= qq{<H2 CLASS="$base_css_class">Form Data:</H2>\n};

    # clone form data so it's still ok for plain when we tweak it for html here
    my @data_form = @{ $self->_data_form() };  
    $_->[1] =~ s{ \n }{<br>\n}xms for @data_form;  # turn \n to <br>
    $html .= $qt->render( \@data_form );

    my $data_files = $self->_data_files();
    if (defined $data_files) {
        $html .= qq{<H2 CLASS="$base_css_class">Uploaded Files:</H2>\n};
        $html .= $qt->render( $data_files );
    }

    my $data_env = $self->_data_env();
    if (defined $data_env) {
        $html .= qq{<H2 CLASS="$base_css_class">Browser/Connect Info:</H2>\n};
        $html .= $qt->render( $data_env );
    }

    $html .= qq{<H2 CLASS="$base_css_class">Time:</H2>\n};

    $html .= $qt->render( $self->_data_time() );

    #print $html;

    return $html;
}

sub _skipfields_lookup {
    my ($self) = @_;

    return $self->{_skipfields_lookup} if exists $self->{_skipfields_lookup};

    my $skipfields_lookup
        = $self->{_skipfields_lookup}
        = { map { ( $_ => 1 ) } @{ $self->{skipfields} } };
    
    return $skipfields_lookup;
}

sub _file_field_names {
    my ($self) = @_;

    my $fbflds = $self->{_fbflds};

    my $skipfields_lookup = $self->_skipfields_lookup;

    return (
        grep { !exists $skipfields_lookup->{$_} } # is not skipped
        grep { $fbflds->{$_}->type eq 'file' }    # type is file
        $self->{form}->fields                     # in order of fields
    );
}

sub _file_attachments {
    my ($self) = @_;

    my ($form, $fbflds) = @{$self}{qw( form _fbflds )};

    return (    # return array of hashrefs suitable for MIME::Type attachments
        map { { Type        => 'AUTO', 
                FH          => $form->field($_),
                Filename    => $form->field($_),
                Id          => $_,
                Disposition => 'attachment',
              } 
            }
            grep { $fbflds->{$_}->value }   # only files actually uploaded
            $self->_file_field_names()
    );
}

sub _data_form {
    my ($self) = @_;

    # might be called twice in 'both', so no need to re-generate
    return $self->{_data_form} if exists $self->{_data_form};

    my ($form, $fbflds) = @{$self}{qw( form _fbflds )};

    my $skipfields_lookup = $self->_skipfields_lookup;

    my $data = [ 
        [ 'Field' => 'Value' ] 
    ];

    my @field_names = $form->fields;


    FIELD:
    foreach my $name ( @field_names ) {
        next FIELD if exists $skipfields_lookup->{$name};
        next FIELD if $fbflds->{$name}->type eq 'file';
        my @values = $form->field($name);
        my $value = join("\n",@values);
        $value = '&nbsp;' if !$value;
        push @{$data}, [ "$name" => $value ];
    }

    # cache in self
    $self->{_data_form} = $data;
    return $data;
}

sub _data_files {
    my ($self) = @_;

    return $self->{_data_files} if exists $self->{_data_files};

    my ($form) = @{$self}{qw( form )};

    my $data = undef;

    my @file_field_names = $self->_file_field_names();

    if (scalar @file_field_names) {
        $data = [ 
            [ 'Field' => 'Attachment Status', ],
        ];
        foreach my $name (@file_field_names) {
            my $value = $form->field($name);
            $value    = 'Not Uploaded' if !defined $value;
            push @{$data}, [ "$name" => "attached as $value" ];
        }
    }
    $self->{_data_files} = $data;

    return $data;
}

sub _data_env {
    my ($self) = @_;
    return $self->{_data_env} if exists $self->{_data_env};

    my $data = undef;
    if (scalar(keys %ENV)) {
        $data = [
            [ 'Item', 'Value' ],
            (   map { [ $_ => $ENV{$_} ] } 
                grep exists $ENV{$_} && defined $ENV{$_},
                qw( HTTP_USER_AGENT HTTP_REFERER REMOTE_ADDR REQUEST_URI )
            ),
        ];
    }
    $self->{_data_env} = $data;
    
    return $data;
}

sub _data_time {
    my ($self) = @_;
    return $self->{_data_time} if $self->{_data_time};

    my $data = [
        [ 'Time Zone'       => 'Time' ],
        [ 'Local System'    => scalar localtime ],
        [ 'Greenwich Mean'  => scalar gmtime    ],
    ];

    $self->{_data_time} = $data;

    return $data;
}

1;

__END__

=head1 NAME

CGI::FormBuilder::Mail::FormatMultiPart 

Plugin for CGI::FormBuilder->mailresults()

=head1 SYNOPSIS

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

=head1 DESCRIPTION

A plugin for CGI::FormBuilder to prettily send the form submission
via e-mail, without requiring the presence of sendmail on the system
or using a shell escape (i.e. Windows).  It uses MIME::Lite to build
the message and that module's interface to Net::SMTP to send it.

Default message format is 'plain' but you can specify 'html' or 'both',
which results in a multipart message.  (Not sure if I have that right yet.)

If HTML, can pass a stylesheet that is printed in-line, as well as
arguments to HTML::QuickTable.  ('header' is ignored.)  The default
style class is 'fb_mail' for all elements.  You can use a partial CSS spec
to override this class's styles; defaults will otherwise still apply.

Will attach all file uploads as multipart MIME attachments.
The file names are listed in the form data table.

If it cannot be used, it will puke a warning message and die.

=head1 INSTALLATION

If you cannot use CPAN or PPM in the normal way, then:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

You need superuser/administrator privileges for the last step.

=head1 WRITING YOUR OWN PLUGIN

This establishes a simple mail plugin implementation standard 
for your own mailresults() plugins.  The plugin should reside 
under the CGI::FormBuilder::Mail::* namespace.  
It should have a constructor new() which accepts
a hash-as-array of named arg parameters, including form => $form.  
It should have a mailresults() object method that does the right thing.
It should use CGI::FormBuilder::Util and puke() if something goes wrong.

Calling $form->mailresults( plugin => 'Foo', ... ) will use
CGI::FormBuilder::Mail::Foo and will pass the FormBuilder object
as a named param 'form' with all other parameters passed intact.

If it should croak, confess, die or otherwise break if something
goes wrong, FormBuilder.pm will warn any errors and the built-in
mailresults() method will still try.

=head1 BUGS

Styles don't do anything in my copy of Evolution, at least.
But they do have the intended effect in Mozilla Mailnews,
so I guess it's good to go.

=head1 DEPENDENCIES

L<MIME::Types>,
L<Net::SMTP>,
L<MIME::Lite>,
L<Text::FormatTable>,
L<HTML::QuickTable>,
L<CGI::FormBuilder version 3.0301 or higher>

=head1 SEE ALSO

L<CGI::FormBuilder>,
L<MIME::Lite>,
L<Text::FormatTable>,
L<HTML::QuickTable>

=head1 AUTHOR

Copyright (c) 2006 Mark Hedges <hedges@ucsd.edu>.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
