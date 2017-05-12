##======================================================================
## Authors:
##    Martial.Chateauvieux@sfs.siemens.de
##    O.Capdevielle@cadextan.fr
##======================================================================
## Copyright (c) 2001, Siemens Financial Services. All rights reserved.
## This library is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##======================================================================
## $Log:$
##======================================================================

package Data::Reconciliation;

require 5.005_62;
use strict;
use warnings;

use Data::Table;
use Carp;

use Data::Reconciliation::Rule;

require Exporter;

our $VERSION = '0.07';

sub new {
    my $class = shift;
    my $source1 = shift;
    my $source2 = shift;
    my %prms = @_;

    croak 'Sources must be of type Data::Table'
	if (! eval {$source1->isa('Data::Table')}) ||
	    (! eval {$source2->isa('Data::Table')});
    
    my @rules;
    if (exists $prms{-rules}) {
	@rules = @{$prms{-rules}};

	croak 'Invalid Data::Reconciliation::Rule'
	    if grep(! eval {$_->isa('Data::Reconciliation::Rule')},
		    @rules);
	
    } else {
	my $r = new Data::Reconciliation::Rule;
	$r->identification([0], undef, [0], undef);

	my $col_nb = 0;
	foreach ($source1->header) {
	    $r->add_comparison([++$col_nb], undef, [$col_nb], undef, undef);
	}
	push @rules, $r;
    }

    return bless {'srcs' => [$source1, $source2],
		  'rules' => \@rules,
		  #'result-store' => $result_store
	      }, $class;
}

sub build_signatures {
    my $this    = shift;
    my $rule_nb = shift;

    croak 'usage: $r->build_signatures(<rule_nb>);'
	if ! defined $rule_nb;

    croak 'invalid rule nb'
	if $rule_nb >= @{$this->{'rules'}};

    for my $src_nb (0 .. 1) {
	my %signature;
	my $rule = $this->{'rules'}->[$rule_nb];
	my $src = $this->{'srcs'}->[$src_nb];
	    for(my $i = 0 ; $i < $src->nofRow ; $i++) {
		push @{$signature{$rule->signature($src_nb, $src->rowRef($i))}}, $i;
	    }
	$this->{'signatures'}->[$src_nb] = \%signature;
    }
}

sub signatures {
    my $this = shift;
    return ([], []) if ! defined $this->{'signatures'};
    return @{$this->{'signatures'}};
}

sub duplicate_signatures {
    my $this = shift;
    my @results;
    foreach my $src_nb (0..1) {
	my $signature = $this->{'signatures'}->[$src_nb];
	$results[$src_nb] = { 
	    map { 
		($_ => $signature->{$_})
		} grep(1 < @{$signature->{$_}}, keys %$signature)
	}
    }
    return @results;
}

sub _delete {
    my $this = shift;
    my @signs = @_;
    my @results = ({},{});
    foreach my $src_nb (0..1) {

	my $signs = $signs[$src_nb];
	next if @$signs == 0;

	my $src = $this->{'srcs'}->[$src_nb];
	my $signature = $this->{'signatures'}->[$src_nb];

	%{$results[$src_nb]} = map { ($_ => delete $signature->{$_}) } @$signs;
    }
    return @results;
}

sub delete_dup_signatures {
    my $this = shift;
    return $this->_delete(map {[keys %$_]} $this->duplicate_signatures);
}

sub widow_signatures {
    my $this = shift;
    my @results = ({},{});
    foreach my $src_nb (0..1) {
	
	my $sign = $this->{'signatures'}->[$src_nb];
	my $sign_other_src = $this->{'signatures'}->[ $src_nb == 0 ? 1 : 0 ];
	my $result = $results[$src_nb];

	%$result = map {($_ =>$sign->{$_})}
	            grep(! exists $sign_other_src->{$_}, keys %$sign);

#  	foreach my $sign (keys %$sign) {
#  	    push @$result, ($sign => $sign->{$sign})
#  		if ! exists $sign_other_src->{$sign};
#  	}
    }
    return @results;
}

sub delete_wid_signatures {
    my $this = shift;
    return $this->_delete(map {[keys %$_]} $this->widow_signatures);
}

sub reconciliate {
    my $this = shift;
    my $rule_nb = shift;

    croak 'usage: $r->reconciliate(<rule_nb>);'
	if ! defined $rule_nb;

    croak 'invalid rule nb'
	if $rule_nb >= @{$this->{'rules'}};

    my $rule = $this->{'rules'}->[$rule_nb];
    my @results;

    my $sign_1 = $this->{'signatures'}->[0];
    my $src_1  = $this->{'srcs'}->[0];
    my $sign_2 = $this->{'signatures'}->[1];
    my $src_2  = $this->{'srcs'}->[1];

    foreach my $signature (keys %$sign_1) {

	(my $idx1) = @{$sign_1->{$signature}};
	(my $idx2) = @{$sign_2->{$signature}};

	my $rec1 = [ $src_1->row($idx1) ];
	my $rec2 = [ $src_2->row($idx2) ];

	push @results, map {
#	    if ($mode eq 'all') {
		[$signature, [$idx1, $idx2], $rule, $_];
#  	    } elsif ($mode eq 'ok') {
#  		$_ ? () : [$key, $rule, $_];
#  	    } else {
#  		$_ ? [$key, $rule, $_] : ();
#  	    }
	} $rule->compare($rec1, $rec2);
	
    }

    return @results;
}

1;
__END__

=head1 NAME

Reconciliation - Perl extension for data reconciliation

=head1 SYNOPSIS

   use Data::Table;

   use Data::Reconciliation;
   use Data::Reconciliation::Rule;

   my $src1 = Data::Table::fromCSV('test1.dat');
   my $src2 = Data::Table::fromCSV('test2.dat');

   my $rule = new Data::Reconciliation::Rule($src1, $src2);

   $rule->identification([<col_names>], \&canon_sub_1,
			 [<col_names>], \&canon_sub_2);
   $rule->add_comparison([<col_names>], \&canon_sub_3,
			 [<col_names>], \&canon_sub_4,
			 \&compare_sub, \@constants);

   my $r = new Data::Reconciliation($src1, $src2,
				    -rules => [$rule]);

   $r->build_signatures(0);

   my($dup_signs_1,
      $dup_signs_2) = $r->duplicate_signatures;

   my($dup_signs_1,
      $dup_signs_2) = $r->delete_dup_signatures;

   my($widow_signs_1,
      $widow_signs_2) = $r->widow_signatures;

   my($widow_signs_1,
      $widow_signs_2) = $r->delete_wid_signatures;

   my @diffs = $r->reconciliate(0);

   package UserFunctions;

   sub fun_1 (\@\@\@\@;\@$) {
       my $field_names_1  = shift;
       my $field_values_1 = shift;
       my $field_names_2  = shift;
       my $field_values_2 = shift;
       
       my $constants      = shift;
       my $func_name      = shift;
       
       my $ok = (...);
       
       return undef if $ok;
       return "Not ok (comparing with $func_name)";
   }

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 

=item new

This creates a new C<Data::Reconciliation> object. The first two
parameters are the sources to be reconciliated. They must be
C<Data::Table> objects.

The other parameters are optional named parameters.

=back

=head2 CONSTRUCTOR OPTIONS

=over 

=item C<-rules =E<gt> [ E<lt>rule listE<gt> ]>

Provides the reconciliations rules. Each rule must be a
C<Reconciliated::Data::Rule> object (L<Reconciliated::Data::Rule>.)
The default rule uses the first column for the C<identification> and
compares one to one the other columns.

=back

=head2 METHODS

=over 

=item C<build_signatures>

This method is used to initialise a reconciliation process. It will
setup the data needed to identify the records to be compared in the
two sources. The rule number must be provided as parameter.

=item C<signatures>

Returns two hash refs containing duplicate signatures as keys and
array refs containing record indices as values. These signatures are
the signatures actually built by the C<build_signatures> method above.

=item C<duplicate_signatures>

This method identifies in the two sources signatures which are not
uniques. The rule nb must be provided as parameter. (The actual
reconciliation algorithm only works on source with cardinality 1..1).

Returns two hash refs containing duplicate signatures as keys and
array refs containing record indices as values.

=item C<delete_dup_signatures>

Returns two hash refs containing the deleted signatures as keys and
array refs containing record indices as values. The duplicates keys
are calculated by calling the C<duplicate_signatures> method.

=item C<widow_signatures>

Returns two hash refs containing signatures from one data source
missing in the other as keys and array refs containing record indices
as values.

=item C<delete_wid_signatures>

Returns two hash refs containing the deleted sigantures as values and
record indices as values. The widow keys are calculated by calling the
C<widow_keys> method.

=item C<reconciliate>

Returns a list of array refs. Each entry being an array containing
respectively the signature, a reference on an arrayref containing the
record indices in the sources, a reference on the applied rule, and a
string describing the difference as returned by the (user defined ?)
comparison function.

for C<reconciliate> To work properly it is necessary to remove
duplicate and widow signatures.

=back

=head1 EXAMPLE

    #!/usr/local/bin/perl -w

    use lib qw(../lib);

    use Data::Table;

    use Data::Reconciliation;
    use Data::Reconciliation::Rule;

    my $file1 = new Data::Table
        ([['1234',  0,  '123,45', 'FRF'],
          ['1234',  1, '-123,45', 'FRF'],
          ['1235',  0,  '122,45', 'FRF'],
          ['1236',  0,  '121,50', 'FRF'],
          ['1237',  0,  '121,50', 'FRF'],
          ['1237',  0,  '50,121', 'CHF']],
         ['dealnb', 'leg', 'amt',     'ccy']);
    my $file2 = new Data::Table
        ([['1234-0',  123.45, 'FRF'],
          ['1234-1', -123.45, 'FRF'],
          ['1235-0',  122.47, 'FRF'],
          ['1236-0',  121.50, 'DEM'],
          ['1239-0',  50.121, 'CHF']],
         ['external-key', 'Amount',    'ccy']);

    my $rule = new Data::Reconciliation::Rule($file1, $file2);

    $rule->identification(['dealnb', 'leg'], sub{ join '-', @_ },
    		          ['external-key'], undef);
    $rule->add_comparison(['amt'], sub {(my $v = shift) =~ tr/,/./; $v},
		          ['Amount'], undef,
		      undef);
    $rule->add_comparison(['ccy'], undef,
		          ['ccy'], undef,
		          undef);

    my $r = new Data::Reconciliation($file1,
			             $file2,
				     -rules => [$rule]);

    $r->build_signatures(0);

    my($dup_signs_from_1,
       $dup_signs_from_2) = $r->delete_dup_signatures;

    my($widow_signs_1,
       $widow_signs_2) = $r->delete_wid_signatures;

    print "The following signatures in Table1 leads to multiple entries :\n\t[",
        join('][', sort keys %$dup_signs_from_1), "]\n"
        if keys %$dup_signs_from_1;

    print "The following signatures in Table2 leads to multiple entries :\n\t[",
        join('][', sort keys %$dup_keys_from_2), "]\n"
        if keys %$dup_keys_from_2;

    print "The following entries in Table1 have no correspondant in Table 2 :\n\t[",
        join('][', sort keys %$widow_signs_1), "]\n"
        if keys %$widow_signs_1;

    print "The following entries in Table2 have no correspondant in Table 1 :\n\t[",
        join('][', sort keys %$widow_signs_2), "]\n"
        if keys %$widow_signs_2;

    @diffs = $r->reconciliate(0);
    print "The following entries were found to be different :\n\t",
        join("\n\t", map {$_->[0] . ': ' .  $_->[3]} @diffs), "\n"
        if @diffs;

=head1 EXAMPLE OUPUT

   The following signatures in Table1 leads to multiple entries :
        [1237-0]
   The following entries in Table2 have no correspondant in Table 1 :
        [1239-0]
   The following entries were found to be different :
        1236-0: SRC1.ccy=[FRF] <> SRC2.ccy=[DEM]
        1235-0: SRC1.amt=[122.45] <> SRC2.Amount=[122.47]

=head1 AUTHORS

Martial.Chateauvieux@sfs.siemens.de, 
O.Capdevielle@cadextan.fr

=head1 SEE ALSO

L<Data::Reconciliation>, L<Data::Table>

=cut
