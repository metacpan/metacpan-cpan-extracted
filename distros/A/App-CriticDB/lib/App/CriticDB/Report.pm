package App::CriticDB::Report;

use strict;
use warnings;
use Perl::Critic::Violation;

our $VERSION='0.0.4';

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my $self=bless({
		format=>undef,
		%opt,
		violations=>$opt{violations},
		},$class);
	$$self{verbose}//="%f: %m at line %l, column %c.  (Severity: %s)\n";
	Perl::Critic::Violation::set_format($$self{verbose});
	return $self;
}

sub text {
	my ($self,$violation)=@_;
	my @violations;
	if($violation) { @violations=($violation) }
	else           { @violations=@{$$self{violations}} }
	return join('',map {$_->to_string()} @violations);
}

1;

__END__

=pod

=head1 NAME

App::CriticDB::Report - Build reports of violations

=head1 VERSION

Version 0.0.4

=head1 SYNOPSIS

  use App::CriticDB::Report;
  my $report=App::CriticDB::Report->new(
    verbose   =>'... format ...',
    violations=>\@violations);
  print $report->text();

=head1 DESCRIPTION

For single or multiple violations, output violations in a form equivalent to C<perlcritic --verbose>.

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut

