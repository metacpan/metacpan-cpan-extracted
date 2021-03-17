package Dancer2::CLI;
# ABSTRACT: Dancer2 cli application
$Dancer2::CLI::VERSION = '0.301001';
use strict;
use warnings;

BEGIN {
    eval {
        require App::Cmd::Setup;
        1; 
    } or do {
        warn <<INSTALLAPPCMD;
ERROR: You need to install App::Cmd first to use this tool.

You can do so using your preferred module installation method, for instance;

  # using cpanminus
  cpanm App::Cmd
  # or using CPAN.pm
  cpan App::Cmd
  
For more detailed instructions, see http://www.cpan.org/modules/INSTALL.html

Without App::Cmd, the `dancer2` app minting tool cannot be used, but Dancer2
can still be used for existing apps.
INSTALLAPPCMD
        exit;
    }
}

use App::Cmd::Setup -app;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::CLI - Dancer2 cli application

=head1 VERSION

version 0.301001

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
