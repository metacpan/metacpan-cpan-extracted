package Buscador::Raw;
use strict;

# put path munging stuff here

sub parse_path_order { 13 }

sub parse_path {
    my ($self, $buscador) = @_;

    $buscador->{path} =~ s!raw/!mail_raw/!;
}

=head1 NAME

Buscador::Raw - Buscador plugin to provide a raw version of a mail

=head1 DESCRIPTION

This prints out a raw message when you do

    ${base}/mail/raw/<id>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004, Simon Wistow

=cut


package Email::Store::Mail;
use strict;

sub mail_raw :Exported {
      my ($self,$r, $mail)  = @_;

    
    my $output;
    

    if (defined $mail) {
        $output         = $mail->raw || $mail->message;
    }

    $output = "[ no content ]" unless defined $output;


    $r->{content_type} = "text/plain";
    $r->{output}       = $output;    
}



1;
