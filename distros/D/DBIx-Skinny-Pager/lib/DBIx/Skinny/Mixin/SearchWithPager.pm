package DBIx::Skinny::Mixin::SearchWithPager;
use strict;
use warnings;
use UNIVERSAL::require;

sub register_method {
    +{
        'search_with_pager' => \&search_with_pager,
    };
}

sub search_with_pager {
    my ($class, $table, $where_cnd, $option_cnd, ) = @_;
    my $pager_logic = delete $option_cnd->{pager_logic};
    my $page = delete $option_cnd->{page};
    my $rs = $class->search_rs($table, $where_cnd, $option_cnd);
    my $logic_class = "DBIx::Skinny::Pager::Logic::$pager_logic";
    $logic_class->require
        or die $@;
    bless $rs, $logic_class; # rebless resultset.
    $rs->page($page) if $page;
    $rs->retrieve();
}

1;

__END__

=head1 NAME

DBIx::Skinny::Mixin::SearchWithPager

=head1 SYNOPSIS

    package Proj::DB;
    use DBIx::Skinny;
    use DBIx::Skinny::Mixin modules => ['Pager', 'SearchWithPager' ];

    package main;
    use Proj::DB;

    my ($iter, $pager) = Proj::DB->search_with_pager(bar => {
        foo => "bar",
    }, {
        page => 1,
        limit => 10,
        pager_logic => "MySQLFoundRows",
    });

