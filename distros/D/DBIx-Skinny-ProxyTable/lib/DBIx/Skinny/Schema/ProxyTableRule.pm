package DBIx::Skinny::Schema::ProxyTableRule;
use strict;
use warnings;

sub import {
    my $caller = caller;
    my $_proxy_table_rule = {};
    {
        no strict 'refs';
        *{"$caller\::proxy_table_rules"} = sub { $_proxy_table_rule };
        *{"$caller\::proxy_table_rule"} = \&proxy_table_rule;
    }
}

sub proxy_table_rule(@) { ## no critic
    my ($func, @args) = @_;
    my $class = caller;
    $class->proxy_table_rules->{ $class->schema_info->{_installing_table} } = [ @_ ];
}

1;
__END__

=head1 NAME

DBIx::Skinny::Schema::ProxyTableRule

=head1 SYNOPSIS

  package Proj::DB::Schema;
  use DBIx::Skinny::Schema;
  use DBIx::Skinny::Schema::ProxyTableRule;

  install_table 'access_log' => shcema {
    proxy_table_rule 'named_strftime', 'access_log_%Y%m', 'accessed_on';

    pk 'id';
    columns qw/id/;
  };

  package main;

  my $rule = Proj::DB->proxy_table->rule('access_log', accessed_on => DateTime->today);
  $rule->table_name; #=> "access_log_200901"

  # create table that name is "access_log_200901"
  $rule->copy_table;

  my $iter = Proj::DB->search($rule->table_name, { foo => 'bar' });

=head1 DESCRIPTION

DBIx::Skinny::Schema::ProxyTableRule export proxy_table_rule method.
You can call proxy_table_rule method in install_table method.

=head1 METHOD

=head2 proxy_table_rule($funcname_or_coderef, @default_args)

1st argumet is funtion name (strftime or sprintf) or CODEREF

=head3 named_strftime

If you define rule followings:
    package Proj::DB::Schema;
    use DBIx::Skinny::Schema;
    use DBIx::Skinny::Schema::ProxyTableRule;

    install_table 'access_log' => schema {
        proxy_table_rule 'named_strftime', 'access_log_%Y%m', 'accessed_on';
    };

you can call followings:

    my $rule = Proj::DB->proxy_table->rule('access_log', accessed_on => DateTime->now);
    $rule->table_name #=> "access_log_201002"

=head3 keyword

If you define rule followings:
    package Proj::DB::Schema;
    use DBIx::Skinny::Schema;
    use DBIx::Skinny::Schema::ProxyTableRule;

    install_table 'access_log' => schema {
        proxy_table_rule 'keyword', 'access_log_<%04d:year><%02d:month>';
    };

you can call followings:

    my $now = DateTime->now;
    my $rule = Proj::DB->proxy_table->rule('access_log', year => $now->year, month => $now->month);
    $rule->table_name #=> "access_log_201002"

second argument's format is like <sprintf_format:keyword_key>. Each keywords are replaced by CORE::sprintf.

=head3 sprintf

If you define rule followings:
    package Proj::DB::Schema;
    use DBIx::Skinny::Schema;
    use DBIx::Skinny::Schema::ProxyTableRule;

    install_table 'access_log' => schema {
        proxy_table_rule 'sprintf', 'access_log_%04d%02d';
    };

you can call followings:

    my $now = DateTime->now;
    my $rule = Proj::DB->proxy_table->rule('access_log', $now->year, $now->month);
    $rule->table_name #=> "access_log_201002"

I recommend to use keyword, than this. If you make mistake to specify argument order,
it may cause some problem.

=head3 strftime

If you define rule followings:
    package Proj::DB::Schema;
    use DBIx::Skinny::Schema;
    use DBIx::Skinny::Schema::ProxyTableRule;

    install_table 'access_log' => schema {
        proxy_table_rule 'strftime', 'access_log_%Y%m';
    };

you can call followings:

    my $rule = Proj::DB->proxy_table->rule('access_log', DateTime->now);
    $rule->table_name #=> "access_log_201002"

I recommend to use named_strftime, than this. If you make mistake to send rule to not accessed_on but created_on,
it may cause some problem.

=head3 CODEREF

You can define custom function.

If you define rule followings:
    package Proj::DB::Schema;
    use DBIx::Skinny::Schema;
    use DBIx::Skinny::Schema::ProxyTableRule;

    my $code = sub {
        my ($template, @args) = @_;
        sprintf($template, @args);
    };
    install_table 'access_log' => schema {
        proxy_table_rule \$code, 'access_log_%02d%02d';
    };

you can call followings:

    my $now = DateTime->now;
    my $rule = Proj::DB->proxy_table->rule('access_log', $now->year, $now->month);
    $rule->table_name #=> "access_log_201002"

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

L<DBIx::Skinny::ProxyTable>, L<DBIx::Skinny::ProxyTable::Rule>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
