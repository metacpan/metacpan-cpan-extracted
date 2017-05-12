# $Id: Message.pm,v 1.5 2002/08/30 10:19:36 joern Exp $

package CIPP::Compile::Message;

use Carp;

# This minimum interface must be provided for Message
# classes, which are used by new.spirit.

sub get_name			{ shift->{name}				}
sub get_type			{ shift->{type}				}
sub get_message			{ shift->{message}			}

# Additional CIPP specific information

sub get_line_nr			{ shift->{line_nr}			}
sub get_tag			{ shift->{tag}				}

sub new {
	my $class = shift;
	my %par = @_;

	my  ($type, $message, $name, $line_nr, $tag) =
	@par{'type','message','name','line_nr','tag'};

	confess "Message type '$type' must be 'warn', 'perl_err', 'cipp_err'"
		unless $type eq 'warn' or
		       $type eq 'perl_err' or
		       $type eq 'cipp_err';

	confess "No message given"
		if not defined $message;

	confess "No name given"
		if not defined $name;

	my $self = {
		type	  => $type,
		message   => $message,
		name      => $name,
		line_nr   => $line_nr,
		tag       => uc($tag),
	};
	
	return bless $self, $class;
}

1;
