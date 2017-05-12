# $Id: Exception.pm,v 1.9 2002/06/11 07:44:30 matt Exp $

package AxKit::XSP::Exception;

use strict;
use Apache::AxKit::Language::XSP;

use vars qw/@ISA $NS $VERSION $ForwardXSPExpr @E_state/;

@ISA = ('Apache::AxKit::Language::XSP');
$NS = 'http://axkit.org/NS/xsp/exception/v1';

$VERSION = "1.6";

sub start_document{
        my ($e) = shift;
        @E_state = ();
        return;
}

sub parse_char {
    my ($e, $text) = @_;
    return '';
}

my $sort_nodes = ' for ($parent->childNodes()) { $_->unbindNode; $real_parent->appendChild($_); } ';

sub parse_start {
    my ($e, $tag, %attribs) = @_;
     
    if ($tag eq 'try') {
          $e->manage_text(0);
          push(@E_state, "try");
          return 'eval { my $real_parent = $parent; my $parent = $document->createElement("psuedo-parent"); '. "\n";
          
    }
    elsif ($tag eq 'catch') {
        $e->manage_text(0);
        my $state = pop(@E_state);
        if($state eq 'try') {
            if(my $class = $attribs{'class'}) {  
                push(@E_state, 'catch');
                return "$sort_nodes\n };\n".' if($@) { my $exception = $@; if($@->isa("'.$class.'")) { ';
            }
            else {
                push(@E_state, 'catchall');
                return "$sort_nodes\n };\n".' if($@) { my $exception = $@; ';
            }
        }
        elsif($state eq 'catch') {
            if(my $class = $attribs{'class'}) {
                push(@E_state, 'catch');
                return '} elsif($@->isa("'.$class.'")) { ';
            }
            else {
                push(@E_state, 'catchelse');
                return '} else { ';
            }
        }
        else {
            die "catch can only be called after a try tag";
        }
    }
    elsif ($tag eq 'message') {
        $e->start_expr($tag);
        return '';
    }
    else {
        die "Unknown exceptions tag: $tag";
    }
}

sub parse_end {
    my ($e, $tag) = @_;
    if ($tag eq 'try') {
        my $state = pop(@E_state);
        if($state eq 'try') {
            # Not sure this is right - surely if you wrap the whole thing
            # in a try block, with no catch, you just want to ignore the
            # exceptions?
            return $sort_nodes.'}; if($@) { die($@) }; ';     # No if($@) block
        }
        elsif($state eq 'catch') { 
            return '} else { die($@) } }; undef($@); ';       # if($@) { block --propogate die
        }
        elsif($state eq 'catchall') {
            return '} undef($@); ';              # if($@) { block -- don't propogate die
        }
        elsif($state eq 'catchelse') {
            return '}} undef($@); ';                          #if($@) {} else { block -- don't propogate die
        }
    }
    elsif ($tag eq 'catch') {
        $e->manage_text(0);
        return '';
    }
    elsif ($tag eq 'message') {
        $e->append_to_script('$exception');
        $e->end_expr();
        return '';
    }
}

1;
__END__

=head1 NAME

AxKit::XSP::Exception - Exceptions taglib for eXtensible Server Pages

=head1 SYNOPSIS

Add the sendmail: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:except="http://axkit.org/NS/xsp/exception/v1"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::Exception

=head1 DESCRIPTION

Allows you to catch exceptions thrown by either your own code, or other
taglibs.

=head1 EXAMPLE

This example shows all the tags in action:

  <except:try>
   <mail:send-mail>...</mail:send-mail>
   <except:catch class="Some::Exception::Class">
           <!-- Handle this error differently. -->
   </except:catch>
   <except:catch>
           <!-- all uncaught errors get caught here -->
    <p>An Error occured: <except:message/></p>
   </except:catch>
  </except:try>

=head1 AUTHOR

Matt Sergeant, matt@axkit.com

=head1 COPYRIGHT

Copyright (c) 2001 AxKit.com Ltd. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

AxKit

=cut
