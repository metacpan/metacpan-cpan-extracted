package ACME::Error::HTML;

use strict;
no  strict 'refs';

use vars q[$VERSION];
$VERSION = '0.01';

use HTML::FromText;

*die_handler = *warn_handler = sub {
  return text2html "@_",
                   paras        => 1,
                   bold         => 1,
                   metachars    => 0,
                   urls         => 1,
                   email        => 1,
                   underline    => 1,
                   blockparas   => 1,
                   numbers      => 1,
                   bullets      => 1;
};

1;
__END__

=head1 NAME

ACME::Error::HTML - ACME::Error Backend to Markup Errors with HTML

=head1 SYNOPSIS

  use ACME::Error HTML;

  warn "blink"; # <p>blink</p>

=head1 DESCRIPTION

Converts your errors to HTML.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 COPYRIGHT

Copyright (c) 2002 Casey R. West <casey@geeknest.com>.  All
rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1), HTML::FromText.

=cut
