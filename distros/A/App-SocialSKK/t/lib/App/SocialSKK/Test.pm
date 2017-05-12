package App::SocialSKK::Test;
use Net::Ping::External qw();
use Filter::Util::Call;
use base qw(Test::Class Class::Accessor::Lvalue::Fast);

__PACKAGE__->mk_accessors(qw(module));

use Test::More;
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";
binmode Test::More->builder->todo_output,    ":utf8";

my @goodies = qw(
    Test::More
    Test::Exception
    App::SocialSKK::Test::Spec
);

sub import {
    my $class = shift;
    require strict;
    strict->import;
    require warnings;
    warnings->import;
    require utf8;
    utf8->import;

    my $caller = caller;
    unless ($caller eq $class) {
        no strict 'refs';
        push @{$caller . ":\:ISA"}, $class;
    }
    $class->use_goodies;
}

sub use_goodies {
    my $class = shift;
    my $done  = 0;
    Filter::Util::Call::filter_add(
        sub {
            return 0 if $done;
            my ($data, $end) = ('', '');
            while (my $status = Filter::Util::Call::filter_read()) {
                return $status if $status < 0;
                if (/^__(?:END|DATA)__\r?$/) {
                    $end = $_;
                    last;
                }
                $data .= $_;
                $_ = '';
            }
            my $use_statements = (join qq{\n}, (map { qq{use $_;} } @goodies)) . qq{\n};
            $_ = $use_statements . $data . $end;
            $done = 1;
        }
    );
}

sub ping {
    my $self = shift;
    Net::Ping::External::ping(
        hostname => shift,
        timeout  => 3,
        count    => 1,
    );
}

1;
