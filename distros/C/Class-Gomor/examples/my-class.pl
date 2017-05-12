# Create a base class in BaseClass.pm
package My::BaseClass;

require Class::Gomor::Array;
our @ISA = qw(Class::Gomor::Array);

our @AS = qw(attribute1 attribute2);
our @AA = qw(attribute3 attribute4);
our @AO = qw(other);

# Create indices and accessors
My::BaseClass->cgBuildIndices;
My::BaseClass->cgBuildAccessorsScalar(\@AS);
My::BaseClass->cgBuildAccessorsArray(\@AA);

# You should initialize yourself array attributes
sub new { shift->SUPER::new(attribute3 => [], attribute4 => [], @_) }

sub other {
   my $self = shift;
   @_ ? $self->[$self->cgGetIndice('other')] = [ split(/\n/, shift) ]
      : @{$self->[$self->cgGetIndice('other')]};
}

# Create a subclass in SubClass.pm
package My::SubClass;

our @ISA = qw(My::BaseClass);

our @AS = qw(subclassAttribute);

My::SubClass->cgBuildIndices;
My::SubClass->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      attribute1 => 'val1',
      attribute2 => 'val2',
      attribute3 => [ 'val3', ],
      attribute4 => [ 'val4', ],
      other      => [ 'none', ],
      subclassAttribute => 'subVal',
   );
}

# A program using those classes
package main;

my $new = My::SubClass->new;

my $val1     = $new->attribute1;
my @values3  = $new->attribute3;
my @otherOld = $new->other;

$new->other("str1\nstr2\nstr3");
my @otherNew = $new->other;
print "@otherNew\n";

$new->attribute2('newValue');
$new->attribute4([ 'newVal1', 'newVal2', ]);

print $new->cgDumper."\n";
