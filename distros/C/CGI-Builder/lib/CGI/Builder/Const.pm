use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; package CGI::Builder::Const

; our @phase

; BEGIN
   { @phase  = qw | CB_INIT
                    GET_PAGE
                    PRE_PROCESS
                    SWITCH_HANDLER
                    PRE_PAGE
                    PAGE_HANDLER
                    FIXUP
                    RESPONSE
                    REDIR
                    CLEANUP
                  |
   ; my %h
   ; @h{@phase} = (0 .. $#phase)
   ; while ( my ($k, $v) = each %h )
      { no strict 'refs'
      ; *$k = sub () { $v }
      }
   }

; require Exporter
; our @ISA = 'Exporter'
; our @EXPORT_OK   = ( @phase )
; our %EXPORT_TAGS = ( all      => \@phase
                     , phases   => \@phase
                     )
                     
; 1

__END__

=pod

=head1 NAME

CGI::Builder::Const - Deprecated

=head1 DESCRIPTION

Deprecated module.

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
