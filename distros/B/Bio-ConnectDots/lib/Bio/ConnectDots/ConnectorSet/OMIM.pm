package Bio::ConnectDots::ConnectorSet::OMIM;

use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
	my ($self) = @_;
	my $input_fh = $self->input_fh;

	while (<$input_fh>) {
		chomp;
		if (/^\*RECORD\*/) {
			next unless $self->have_dots;
			return 1;
		}  
		if (/^\*FIELD\* NO/) {
			$_ = <$input_fh>;
			chomp;
			$self->put_dot( 'OMIM', $_ );
		}
		if (/^\*FIELD\* TI/) {
			my $title;
			$_ = <$input_fh>;
			chomp;
			$title = $_;
			# attach extra titles
			while (!/^\*/) {
				$_ = <$input_fh>;
				if(!/^\*/) {
					chomp;
					$title .= " $_";
				}
			}
			my @titles = split (/;;/, $title);
			$self->put_dot('Title', shift @titles);
			foreach my $alt (@titles) {
				# handle whitespace
				$alt =~ s/^\s*//;
				$alt =~ s/\s*$//;
				$alt =~ s/\s+/ /;
				$self->put_dot('Alternate_Title', $alt) if $alt;	
			}
			
		}
		if (/^\*RECORD\*/) {
			next unless $self->have_dots;
			return 1;
		}  
	}    #end of while
	return undef;
}

1;
