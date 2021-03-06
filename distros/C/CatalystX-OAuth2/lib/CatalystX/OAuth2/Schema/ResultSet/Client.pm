package CatalystX::OAuth2::Schema::ResultSet::Client;
use parent 'DBIx::Class::ResultSet';

sub find_refresh {
  shift->related_resultset('codes')->search( { is_active => 1 } )
    ->related_resultset('refresh_tokens')->find(@_);
}

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Schema::ResultSet::Client

=head1 VERSION

version 0.001009

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
