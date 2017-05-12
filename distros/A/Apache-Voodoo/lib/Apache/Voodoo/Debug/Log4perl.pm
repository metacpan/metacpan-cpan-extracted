package Apache::Voodoo::Debug::Log4perl;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Debug::Common");

use File::Spec;
use Log::Log4perl;
use Data::Dumper; $Data::Dumper::Terse = 1; $Data::Dumper::Indent = 1;

$Log::Log4perl::caller_depth = 3;

#
# Since log4perl wants to use one config file for the whole running perl program (one
# call to init), and # ApacheVoodo lets you define logging per application (multiple inits).
# We're using a singleton to get around that.  We append each config block to a hash and
# then init log4perl after the all the apps are loaded.  Kinda ugly, but until log4perl supports
# multiple configs, then it's what we're stuck with.
#
our $self;

sub new {
	my $class = shift;
	my $id    = shift;
	my $conf  = shift;

	unless (ref($self)) {
		$self = {};
		$self->{conf} = {};
		bless($self,$class);
	}

	if (ref($conf) eq "HASH") {
		foreach (keys %{$conf}) {
			$self->{conf}->{$_} = $conf->{$_};
		}
	}
	elsif (!ref($conf)) {
		$self->{v_file} = $conf;
	}

	return $self;
}

sub bootstrapped {
	my $self = shift;

	unless (Log::Log4perl->initialized()) {
		my $conf;
		if ($self->{v_file}) {
			if (open(F,$self->{v_file})) {
				local $/ = undef;
				$conf = <F>;
				$conf .= "\n";
				close(F);
			}
			else {
				warn $!
			}
		}
		foreach (keys %{$self->{conf}}) {
			$conf .= $_ .' = '.$self->{conf}->{$_}."\n";
		}

		Log::Log4perl->init_once(\$conf);
	}
}

sub enabled {
	return 1;
}


sub debug     { my $self = shift; $self->_get_logger->debug($self->_dumper(@_)); }
sub info      { my $self = shift; $self->_get_logger->info( $self->_dumper(@_)); }
sub warn      { my $self = shift; $self->_get_logger->warn( $self->_dumper(@_)); }
sub error     { my $self = shift; $self->_get_logger->error($self->_dumper(@_)); }
sub exception { my $self = shift; $self->_get_logger->fatal($self->_dumper(@_)); }

sub trace     { my $self = shift; $self->_get_logger->trace($self->_dump_trace(@_)); }
sub table     { my $self = shift; $self->_get_logger->debug($self->_dump_table(@_)); }

sub return_data   { my $self = shift; $self->_get_logger('ReturnData'  )->trace($self->_dumper(@_)); }
sub url           { my $self = shift; $self->_get_logger('Url'         )->trace($self->_dumper(@_)); }
sub status        { my $self = shift; $self->_get_logger('Status'      )->trace($self->_dumper(@_)); }
sub params        { my $self = shift; $self->_get_logger('Params'      )->trace($self->_dumper(@_)); }
sub template_conf { my $self = shift; $self->_get_logger('TemplateConf')->trace($self->_dumper(@_)); }
sub session       { my $self = shift; $self->_get_logger('Session'     )->trace($self->_dumper(@_)); }

sub mark {
	my $self = shift;

	push(@{$self->{profile}},[@_]);
}

sub shutdown {
	my $self = shift;

	my @d = @{$self->{profile}};
	my $last = $#d;
	if ($last > 0) {
		my $total_time = $d[$last]->[0] - $d[0]->[0];

		my @return = map {
			[
				sprintf("%.5f",    $d[$_]->[0] - $d[$_-1]->[0]),
				sprintf("%5.2f%%",($d[$_]->[0] - $d[$_-1]->[0])/$total_time*100),
				$d[$_]->[1]
			]
		} (1 .. $last);

		unshift(@return, [
			sprintf("%.5f",$total_time),
			'percent',
			'message'
		]);

		my $logger = $self->_get_logger("Profile");
		$logger->debug($self->_dump_table("Profile",\@return));
	}

	delete $self->{profile};
}

sub _dumper {
	my $self = shift;
	my @data = @_;
	return sub {
		if (scalar(@data) > 1 || ref($data[0])) {
			# if there's more than one item, or the item we have is a reference
			# then we need to serialize it.
			return Dumper \@data;
		}
		else {
			return $data[0];
		}
	};
}

sub _get_logger {
	my $self    = shift;
	my $section = shift;

	if ($section) {
		return Log::Log4perl->get_logger("Apache::Voodoo::".$section);
	}
	else {
		my @stack = $self->stack_trace();
		if (scalar(@stack)) {
			return Log::Log4perl->get_logger($stack[-1]->{class});
		}
		else {
			return Log::Log4perl->get_logger("Apache::Voodoo");
		}
	}
}

sub _dump_table {
	my $s = shift;
	my @data = @_;

	return sub {
		my $self = $s;
		my $name = "Table";
		if (scalar(@data) > 1) {
			$name = shift @data;
		}

		return "\n$name\n" . $self->_mk_table(@{$data[0]});
	};
}

sub _dump_trace {
	my $s = shift;
	my $n = shift;
	my $t = [$s->stack_trace()];

	return sub {
		my $self  = $s;
		my $trace = $t;

		my $name = ($n || "Trace");
		my @data = map {
			[
				$_->{class},
				$_->{function},
				$_->{line},
			]
		} @{$trace};

		unshift(@data,['Class','Subroutine','Line']);
		return "\n$name\n".$self->_mk_table(@data);
	};
}

sub _mk_table {
	my $self = shift;
	my @data = @_;

	my @col;
	# find the widest element in each column
	foreach my $row (@data) {
		for (my $i=0; $i < scalar(@{$row}); $i++) {
			if (!defined($col[$i]) || length($row->[$i]) > $col[$i]) {
				$col[$i] = length($row->[$i]);
			}
		}
	}

	my $t_width = 2;	    # "| "
	foreach (@col) {
		$t_width += $_ + 3; # " | "
	}
	$t_width -= 1;          # "| " -> "|"

	my @return;
	push(@return,'-' x $t_width);
	foreach my $row (@data) {
		my $line = "| ";
		for (my $i=0; $i < scalar(@{$row}); $i++) {
			$line .= sprintf("%-".$col[$i]."s",$row->[$i]) . " | ";
		}
		$line =~ s/ $//;
		push (@return,$line);
		push(@return,'-' x $t_width);
	}
	return join("\n",@return);
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
