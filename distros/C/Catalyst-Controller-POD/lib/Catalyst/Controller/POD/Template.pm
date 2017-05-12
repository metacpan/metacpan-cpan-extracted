#
# This file is part of Catalyst-Controller-POD
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package Catalyst::Controller::POD::Template;
BEGIN {
  $Catalyst::Controller::POD::Template::VERSION = '1.0.0';
}

use utf8;

sub get {
    my $class = shift;
    my $root = shift;
    return << "DATA"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
    <head>
    <title>Pod::Browser</title>

    <link rel="stylesheet" type="text/css" href="$root/ext/resources/css/ext-all.css" />
    <link rel="stylesheet" href="$root/cpan.css" type="text/css" />
    <link rel="stylesheet" href="$root/docs.css" type="text/css" />
    <script type="text/javascript" src="$root/ext/adapter/ext/ext-base.js"></script>
    <script type="text/javascript" src="$root/ext/ext-all.js"></script>
    <link href="$root/prettify/prettify.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" src="$root/prettify/prettify.js"></script>
    </head>
    <body>
        <script type="text/javascript">Ext.BLANK_IMAGE_URL = "$root/ext/resources/images/default/s.gif";</script>
        <script type="text/javascript" src="$root/docs.js"></script>
     </body>
</html>
DATA
}

1;

__END__
=pod

=head1 NAME

Catalyst::Controller::POD::Template

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

