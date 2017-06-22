package App::Aliyun;

use strict;
use 5.008_005;
our $VERSION = '0.02';

1;
__END__

=encoding utf-8

=head1 NAME

App::Aliyun - Aliyun Command Tools

=head1 SYNOPSIS

  $ export ALIYUN_ACCESS_KEY=mykey
  $ export ALIYUN_ACCESS_SECRET=mysec
  $ export ALIYUN_REGION_ID=cn-shenzhen

  ### List all regions (useful to test your key/secret)
  $ aliyun-cli-regions

  ### add your public IP in the RDS whitelist for all instances
  $ aliyun-cli-rds-whitelist-my-ip mygroupA

  ### restart instance by name
  $ aliyun-cli-ec2-restart-by-name server1

=head1 DESCRIPTION

You can get your AccessId and AccessSecret from L<https://ak-console.aliyun.com/>

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
