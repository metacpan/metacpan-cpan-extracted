use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

sub normal_cv {
    (my $cv = AE::cv)->send(@_);
    return $cv;
}

sub croak_cv {
    (my $cv = AE::cv)->croak(@_);
    return $cv;
}

{
    my @args;
    is_deeply [croak_cv("NG")->catch(sub {
        @args = @_;
        normal_cv("ok", "good")
    })->recv], [qw/ok good/];
    is @args, 1;
    like $args[0], qr/^NG\b/;
}

eval { croak_cv("NG")->catch(sub { croak_cv(@_) })->recv }, 
like $@, qr/^NG\b/;

is_deeply [normal_cv("ok", "good")->catch(sub { croak_cv("NG") })->recv], 
          [qw/ok good/];

is normal_cv(2)->map(sub { 4 / $_[0] })->catch(sub { normal_cv('-') })->recv,
   2;

is normal_cv(0)->map(sub { 4 / $_[0] })->catch(sub { normal_cv('-') })->recv,
   '-', "catch an implicit error";

done_testing;
