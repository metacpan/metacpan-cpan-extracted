package TAP::Parser::Metrics;
use parent qw/TAP::Parser/;

use strict;
use warnings;

our $VERSION='0.0.3';

my $METRICS='__METRICS__'.int(1e6+rand(9e6));

sub configure {
	my ($self,%opt)=@_;
	if($opt{callback}) { $$self{callback}=$opt{callback} }
	return $self;
}

sub new {
	my ($ref,$argref)=@_;
	my $class=ref($ref)||$ref;
	my $self=$class->SUPER::new($argref);
	$$self{$METRICS}={path=>[],log=>[],source=>$$argref{source}};
	return $self;
}

sub log {
	my ($self,$pass,$file,$label,@path)=@_;
	push @{$$self{$METRICS}{log}},{
		file=>$file,
		pass=>$pass,
		path=>[@path],
		label=>$label,
	};
}

sub next {
	my ($self,@args)=@_;
	my $next=$self->SUPER::next(@args);
	if(!$next) {
		if($$self{callback}) { &{$$self{callback}}(@{$$self{$METRICS}{log}}) }
		return $next;
	}
	my $metrics=$$self{$METRICS};
	if(my $raw=$next->raw()) {
		if($raw=~/^(?<indent>\s*)# Subtest:\s+(?<name>.*)$/) { # subtest begin
			my $indent=length($+{indent})/4;
			if($#{$$metrics{path}}>$indent) { splice(@{$$metrics{path}},$indent) }
			push @{$$metrics{path}},$+{name};
		}
		elsif($raw=~/^(?<indent>\s*)not ok\s+\d+\s+-\s*No tests run for subtest "(?<label>.*)"\s*$/) { # subtest early return
			my $indent=length($+{indent})/4;
			if($#{$$metrics{path}}>$indent) { splice(@{$$metrics{path}},$indent) }
			$self->log(0,$$metrics{source},undef,@{$$metrics{path}//[]});
			pop(@{$$metrics{path}});
		}
		elsif($raw=~/^(?<indent>\s*)(?<not>not )?ok\s+\d+\s+-\s*(?<label>.*)$/) {
			my $indent=length($+{indent})/4;
			if(($#{$$metrics{path}}>=$indent)&&($$metrics{path}[-1] eq $+{label})) { # subtest result
				$self->log(($+{not}?0:1),$$metrics{source},undef,@{$$metrics{path}//[]});
				splice(@{$$metrics{path}},$indent);
			}
			else { # assertion result
				if($#{$$metrics{path}}>=$indent) { splice(@{$$metrics{path}},$indent) }
				$self->log(($+{not}?0:1),$$metrics{source},$+{label},@{$$metrics{path}//[]});
			}
		}
		elsif($raw=~/^(?<indent>\s*)(?<not>not )?ok\s+\d+$/) { # unlabeled assertion
			my $indent=length($+{indent})/4;
			if($#{$$metrics{path}}>=$indent) { splice(@{$$metrics{path}},$indent) }
			$self->log(($+{not}?0:1),$$metrics{source},'',@{$$metrics{path}//[]});
		}
	}
	return $next;
}

1;

__END__
