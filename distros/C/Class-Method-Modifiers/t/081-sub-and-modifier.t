use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @seen;
my $class = MyParent->new();
$class->orig("hi");
is(@seen, 5);
is($seen[0], "before-orig:hi");
is($seen[1], "around-before-orig:hi");
is($seen[2], "orig:hi");
is($seen[3], "around-after-orig:hi");
is($seen[4], "after-orig:hi");

@seen = ();

$class = Child->new();
$class->orig("yo");
is(@seen, 9);
is($seen[0], "Cbefore-orig:yo");
is($seen[1], "Caround-before-orig:yo");
is($seen[2], "before-orig:yo");
is($seen[3], "around-before-orig:yo");
is($seen[4], "orig:yo");
is($seen[5], "around-after-orig:yo");
is($seen[6], "after-orig:yo");
is($seen[7], "Caround-after-orig:yo");
is($seen[8], "Cafter-orig:yo");

@seen = ();

$class = Childer->new();
$class->orig("oy");
is(@seen, 5);
is($seen[0], "CCbefore-orig:oy");
is($seen[1], "CCaround-before-orig:oy");
is($seen[2], "CCorig:oy");
is($seen[3], "CCaround-after-orig:oy");
is($seen[4], "CCafter-orig:oy");

@seen = ();

$class = MyParent2->new();
$class->orig("bye");
is(@seen, 5);
is($seen[0], "before-orig:bye");
is($seen[1], "around-before-orig:bye");
is($seen[2], "orig:bye");
is($seen[3], "around-after-orig:bye");
is($seen[4], "after-orig:bye");

BEGIN
{
    package MyParent;
    use Class::Method::Modifiers;

    sub new { bless {}, shift }

    sub orig
    {
        push @seen, "orig:$_[1]";
    }

    before 'orig' => sub
    {
        push @seen, "before-orig:$_[1]";
    };

    around 'orig' => sub
    {
        my $orig = shift;
        push @seen, "around-before-orig:$_[1]";
        $orig->(@_);
        push @seen, "around-after-orig:$_[1]";
    };

    after 'orig' => sub
    {
        push @seen, "after-orig:$_[1]";
    };
}

BEGIN
{
    package Child;
    our @ISA = 'MyParent';
    use Class::Method::Modifiers;

    before 'orig' => sub
    {
        push @seen, "Cbefore-orig:$_[1]";
    };

    around 'orig' => sub
    {
        my $orig = shift;
        push @seen, "Caround-before-orig:$_[1]";
        $orig->(@_);
        push @seen, "Caround-after-orig:$_[1]";
    };

    after 'orig' => sub
    {
        push @seen, "Cafter-orig:$_[1]";
    };
}

BEGIN
{
    package Childer;
    our @ISA = 'Child';
    use Class::Method::Modifiers;

    sub orig
    {
        push @seen, "CCorig:$_[1]";
    }

    before 'orig' => sub
    {
        push @seen, "CCbefore-orig:$_[1]";
    };

    around 'orig' => sub
    {
        my $orig = shift;
        push @seen, "CCaround-before-orig:$_[1]";
        $orig->(@_);
        push @seen, "CCaround-after-orig:$_[1]";
    };

    after 'orig' => sub
    {
        push @seen, "CCafter-orig:$_[1]";
    };
}
BEGIN
{
    package MyParent2;
    use Class::Method::Modifiers;

    sub new { bless {}, shift }

    around 'orig' => sub
    {
        my $orig = shift;
        push @seen, "around-before-orig:$_[1]";
        $orig->(@_);
        push @seen, "around-after-orig:$_[1]";
    };

    before 'orig' => sub
    {
        push @seen, "before-orig:$_[1]";
    };

    after 'orig' => sub
    {
        push @seen, "after-orig:$_[1]";
    };

    sub orig
    {
        push @seen, "orig:$_[1]";
    }
}

done_testing;
