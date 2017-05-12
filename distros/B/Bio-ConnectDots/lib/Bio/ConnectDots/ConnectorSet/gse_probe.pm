package Bio::ConnectDots::ConnectorSet::gse_probe;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);
my (%platforms, %ids, @ids, $geo);
my $flag = 0;
	
sub parse_entry {
  	my ($self) = @_;
  	my $input_fh=$self->input_fh;
  	while (<$input_fh>) {
		chomp;
		if (/^\!Platform_geo_accession\s*=\s*(GPL\d+)/) {
			$geo = $1;
			$flag = 1;
			$flag = 0 if ($platforms{$geo});
			$platforms{$geo} = 1;
			next;	
		}
		if (/^\^/ && $flag == 1) {
			$flag = 0;
			@ids = ();
			next;
		}
		next unless ($flag == 1);
		if (/^\W(.*?)\s/) {
			my $i = $1;
			push (@ids, uc $i);
			$ids{(uc $i)}=1;
			next;
		}
		my @vals = split('\t');
		next if ($ids[0] eq $vals[0]);
		$self->put_dot("PlatformID","$geo") if $geo;
		my @pass = @ids;
		my ($id, $acc);
		foreach (@vals) {
			my $key = shift @pass;
			if ($key eq 'ID') { $id = $_;}
			if ($key eq 'GI') { $acc = $_;}
			if ($key eq 'GB_ACC') { $acc = $_;}
			if ($key eq 'GB_LIST') { 
				if ($_ =~ /\w+/) {
					$acc .= ",$_" if $acc;
				}
			}
			$self->put_dot($key,$_) if $_;
		}
		if ($acc =~ /,/) {
			my @acc = split(',', $acc);
			foreach (@acc) {
				$self->put_dot("AccessionID",$_) if $_;
			}	
		} else {	
			$self->put_dot("AccessionID",$acc) if $acc;
		}
		return $self->have_dots;
	}
}


1;


