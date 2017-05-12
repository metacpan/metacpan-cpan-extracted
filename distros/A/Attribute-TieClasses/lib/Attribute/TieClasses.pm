use 5.008;
use warnings;
use strict;

package Attribute::TieClasses;
BEGIN {
  $Attribute::TieClasses::VERSION = '1.101700';
}

# ABSTRACT: Attribute wrappers for CPAN Tie classes
use Attribute::Handlers;
no warnings 'redefine';

# Define for each attribute which class to use for which type of
# attribute. I.e., one attribute can cause the referent to be tied
# to different classes depending on whether the referent is a scalar,
# an array etc.
# Each hash value can be a string or a reference to an array of strings.
our %tieclass = (
    __TEST => [
        qw/ SCALAR=Tie::Scalar::Test ARRAY=Tie::Array::Test
          HASH=Tie::Hash::Test /
    ],    # used for test.pl; ignore
    Alias        => 'HASH=Tie::AliasHash',
    Cache        => 'HASH=Tie::Cache',
    CharArray    => 'ARRAY=Tie::CharArray',
    Counter      => 'SCALAR=Tie::Counter',
    Cycle        => 'SCALAR=Tie::Cycle',
    DBI          => 'HASH=Tie::DBI',
    Decay        => 'SCALAR=Tie::Scalar::Decay',
    Defaults     => 'HASH=Tie::HashDefaults',
    Dict         => 'HASH=Tie::TieDict',
    Dir          => 'HASH=Tie::Dir',
    DirHandle    => 'HASH=Tie::DirHandle',
    Discovery    => 'HASH=Tie::Discovery',
    Dx           => 'HASH=Tie::DxHash',
    Encrypted    => 'HASH=Tie::EncryptedHash',
    FileLRU      => 'HASH=Tie::FileLRUCache',
    FlipFlop     => 'SCALAR=Tie::FlipFlop',
    IPAddrKeyed  => 'HASH=Tie::NetAddr::IP',
    Insensitive  => 'HASH=Tie::CPHash',
    Ix           => 'HASH=Tie::IxHash',
    LDAP         => 'HASH=Tie::LDAP',
    LRU          => 'HASH=Tie::Cache::LRU',
    ListKeyed    => 'HASH=Tie::ListKeyedHash',
    Math         => 'HASH=Tie::Math',
    Mmap         => 'ARRAY=Tie::MmapArray',
    NumRange     => 'SCALAR=Tie::NumRange',
    NumRangeWrap => 'SCALAR=Tie::NumRangeWrap=Tie::NumRange',
    Offset       => 'ARRAY=Tie::OffsetArray',
    Ordered      => 'HASH=Tie::LLHash',
    PackedInt    => 'ARRAY=Tie::IntegerArray',
    PerFH        => 'SCALAR=Tie::PerFH',
    Persistent   => 'HASH=Tie::Persistent',
    RDBM         => 'HASH=Tie::RDBM',
    Range        => 'HASH=Tie::RangeHash',
    Rank         => 'HASH=Tie::Hash::Rank',
    Ref          => 'HASH=Tie::RefHash',
    Regexp       => 'HASH=Tie::RegexpHash',
    Secure       => 'HASH=Tie::SecureHash',
    Sentient     => 'HASH=Tie::SentientHash',
    Shadow       => 'HASH=Tie::ShadowHash',
    Sort         => 'HASH=Tie::SortHash',
    Strict       => 'HASH=Tie::StrictHash',
    Substr       => 'HASH=Tie::SubstrHash',
    TextDir      => 'HASH=Tie::TextDir',
    Timeout      => 'SCALAR=Tie::Scalar::Timeout',
    Toggle       => 'SCALAR=Tie::Toggle',
    Transact     => 'HASH=Tie::TransactHash',
    TwoLevel     => 'HASH=Tie::TwoLevelHash',
    Vec          => 'ARRAY=Tie::VecArray',
    WarnGlobal   => 'SCALAR=Tie::WarnGlobal::Scalar',
);

# Define synonyms for each attribute. Each synonym creates another handler,
# so use them sparingly.
# Each hash value can be a string or a reference to an array of strings.
our %synonyms = (
    Alias  => 'Aliased',
    Range  => 'RangeKeyed',
    Rank   => 'Ranked',
    Regexp => 'RegexpKeyed',
    Shadow => 'Shadowed',
    Sort   => 'Sorted',
    Substr => 'Fixed',
    Vec    => 'Vector',
);

# create a handler sub for each attribute definition and each synonym of same
for my $attr (keys %tieclass) {
    my $attrdef = $tieclass{$attr};
    $attrdef = [$attrdef] unless ref $attrdef eq 'ARRAY';
    for my $def (@$attrdef) {
        my ($reftype, $tieclass, $filename) = split /=/, $def;
        $filename ||= $tieclass;
        my $syns = defined $synonyms{$attr} ? $synonyms{$attr} : [];
        $syns = [$syns] unless ref $syns eq 'ARRAY';
        make_handler($_, $reftype, $tieclass, $filename) for $attr, @$syns;
    }
}

# generate and eval the handler code
sub make_handler {
    my ($attr, $reftype, $tieclass, $filename) = @_;
    $filename ||= $tieclass;    # might be several classes in one file
    my $code = qq!
        sub UNIVERSAL::$attr : ATTR($reftype) {
        my (\$ref, \$data) = \@_[2,4];
        \$data = [ \$data ] unless ref \$data eq 'ARRAY';
        eval "use $filename; 1";
    !;
    if    ($reftype eq 'SCALAR') { $code .= make_tie_scalar($tieclass) }
    elsif ($reftype eq 'ARRAY')  { $code .= make_tie_array($tieclass) }
    elsif ($reftype eq 'HASH')   { $code .= make_tie_hash($tieclass) }
    elsif ($reftype eq 'VAR')    { $code .= make_tie_var($tieclass) }
    else                         { die "unknown attribute type $reftype" }
    $code .= "\n} 1\n";
    eval $code or die "Internal error: $@";
}

# subs to generate the variant parts of the attr handler code
sub make_tie_scalar { "tie \$\$ref, '$_[0]', \@\$data\n" }
sub make_tie_array  { "tie \@\$ref, '$_[0]', \@\$data\n" }
sub make_tie_hash   { "tie \%\$ref, '$_[0]', \@\$data\n" }

sub make_tie_var {
    my $tieclass = shift;
    return qq{
        my \$type = ref \$ref;
         (\$type eq 'SCALAR')? tie \$\$ref,'$tieclass',\@\$data
        :(\$type eq 'ARRAY') ? tie \@\$ref,'$tieclass',\@\$data
        :(\$type eq 'HASH')  ? tie \%\$ref,'$tieclass',\@\$data
        : die "Internal error: can't autotie \$type"
    }
}
1;


__END__
=pod

=head1 NAME

Attribute::TieClasses - Attribute wrappers for CPAN Tie classes

=head1 VERSION

version 1.101700

=head1 SYNOPSIS

  use Attribute::TieClasses;
  my $k : Timeout(EXPIRES => '+2s');
  # loads in Tie::Scalar::Timeout and tie()s $k with those options

=head1 DESCRIPTION

Damian Conway's wonderful C<Attribute::Handlers> module provides
an easy way to use attributes for C<tie()>ing variables. In effect,
the code in the synopsis is simply

    use Attribute::Handlers
        autotie => { Timeout => 'Tie::Scalar::Timeout' };

Still, going one step further, it might be useful to have centrally
defined attributes corresponding to commonly used Tie classes found
on CPAN.

Simply C<use()>ing this module doesn't bring in all those potential
Tie classes; they are only loaded when an attribute is actually
used.

The following attributes are defined:

  Attribute name(s)  Variable ref  Class the variable is tied to
  =================  ============  =============================
  Alias              HASH          Tie::AliasHash
  Aliased            HASH          Tie::AliasHash
  Cache              HASH          Tie::Cache
  CharArray          ARRAY         Tie::CharArray
  Counter            SCALAR        Tie::Counter
  Cycle              SCALAR        Tie::Cycle
  DBI                HASH          Tie::DBI
  Decay              SCALAR        Tie::Scalar::Decay
  Defaults           HASH          Tie::HashDefaults
  Dict               HASH          Tie::TieDict
  Dir                HASH          Tie::Dir
  DirHandle          HASH          Tie::DirHandle
  Discovery          HASH          Tie::Discovery
  Dx                 HASH          Tie::DxHash
  Encrypted          HASH          Tie::EncryptedHash
  FileLRU            HASH          Tie::FileLRUCache
  Fixed              HASH          Tie::SubstrHash
  FlipFlop           SCALAR        Tie::FlipFlop
  IPAddrKeyed        HASH          Tie::NetAddr::IP
  Insensitive        HASH          Tie::CPHash
  Ix                 HASH          Tie::IxHash
  LDAP               HASH          Tie::LDAP
  LRU                HASH          Tie::Cache::LRU
  ListKeyed          HASH          Tie::ListKeyedHash
  Math               HASH          Tie::Math
  Mmap               ARRAY         Tie::MmapArray
  NumRange           SCALAR        Tie::NumRange
  NumRangeWrap       SCALAR        Tie::NumRangeWrap (in Tie::NumRange)
  Offset             ARRAY         Tie::OffsetArray
  Ordered            HASH          Tie::LLHash
  PackedInt          ARRAY         Tie::IntegerArray
  PerFH              SCALAR        Tie::PerFH
  Persistent         HASH          Tie::Persistent
  RDBM               HASH          Tie::RDBM
  Range              HASH          Tie::RangeHash
  RangeKeyed         HASH          Tie::RangeHash
  Rank               HASH          Tie::Hash::Rank
  Ranked             HASH          Tie::Hash::Rank
  Ref                HASH          Tie::RefHash
  Regexp             HASH          Tie::RegexpHash
  RegexpKeyed        HASH          Tie::RegexpHash
  Secure             HASH          Tie::SecureHash
  Sentient           HASH          Tie::SentientHash
  Shadow             HASH          Tie::ShadowHash
  Shadowed           HASH          Tie::ShadowHash
  Sort               HASH          Tie::SortHash
  Sorted             HASH          Tie::SortHash
  Strict             HASH          Tie::StrictHash
  Substr             HASH          Tie::SubstrHash
  TextDir            HASH          Tie::TextDir
  Timeout            SCALAR        Tie::Scalar::Timeout
  Toggle             SCALAR        Tie::Toggle
  Transact           HASH          Tie::TransactHash
  TwoLevel           HASH          Tie::TwoLevelHash
  Vec                ARRAY         Tie::VecArray
  Vector             ARRAY         Tie::VecArray
  WarnGlobal         SCALAR        Tie::WarnGlobal::Scalar

I haven't had occasion to test all of these attributes; they were
taken from the module descriptions on CPAN. For some modules where
the name didn't ideally translate into an attribute name (e.g.,
C<Tie::NetAddr::IP>), I have taken some artistic liberty to create
an attribute name. Some tie classes require the use of the return
value from C<tie()> and are as such not directly usable by this
mechanism, AFAIK.

No censoring has been done as far as possible; there are several
attributes that accomplish more or less the same thing. TIMTOWTDI.

If you want any attribute added or renamed or find any mistakes or
omissions, please contact me at <marcel@codewerk.com>.

=head1 FUNCTIONS

=head2 make_handler

Generates and evaluates the attribute handler code. It takes the name of the
attribute to generate, the type of the variable it applies to - scalar, array,
hash, general variable -, the name of the package that implements the
C<tie()>, and the filename where that package lives in.

It calls one of the C<make_tie_*()> functions that provides part of the code to
generate depending on the tied variable type.

=head2 make_tie_array

Returns the code line for the tie of a scalar variable that is needed by
C<make_handler()>.

=head2 make_tie_hash

Returns the code line for the tie of an array variable that is needed by
C<make_handler()>.

=head2 make_tie_scalar

Returns the code line for the tie of a hash variable that is needed by
C<make_handler()>.

=head2 make_tie_var

Is more flexible than the other C<make_tie_*()> functions in that it checks the
type of the variable that the attribute is being applied to.

=head1 EXAMPLES

    # Tie::Scalar::Timeout
    my $m : Timeout(NUM_USES => 3, VALUE => 456, POLICY => 777);
    print "$m\n" for 1..5;

    # Tie::Hash::Rank
    my %scores : Ranked;
    %scores = (
        Adams   => 78,
        Davies  => 35,
        Edwards => 84,
        Thomas  => 47
    );
    print "$_: $scores{$_}\n" for qw(Adams Davies Edwards Thomas);

    # Tie::FlipFlop;
    my $ff : FlipFlop(qw/Red Green/);
    print "$ff\n" for 1..5;

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Attribute-TieClasses/>.

The development version lives at
L<http://github.com/hanekomu/Attribute-TieClasses/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

