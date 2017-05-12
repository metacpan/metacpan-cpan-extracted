package Bundle::Ovid;

$VERSION = '1.01';

1;

__END__

=head1 NAME

Bundle::Ovid - Things Ovid wants in a fresh Perl install

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Ovid'>

=head1 CONTENTS

aliased

Class::DBI

DateTime

DBD::SQLite

DBD::Pg

DBI

Data::Dumper::Simple

Devel::Cover

Devel::Profiler

HTML::TokeParser::Simple

Inline

Regexp::Common

Template

Test::Class

Test::Differences

Test::Exception

Test::MockModule

Test::Pod

Test::Pod::Coverage

Test::WWW::Mechanize

WWW::Mechanize

=head1 DESCRIPTION

Whenever I do a fresh install of Perl, there are certain core modules that I
install over and over again.  I hate doing that so I built this bundle.  Most
modules, even if you don't use them, should be self-explanatory.  Others are
listed below.

=over 4

=item * aliased

This really handy module allows you to use "short names" for long class names:

 use aliased 'Some::Ridiculously::Long::Class::Name::For::Customer';
 my $customer = Customer->new;

=item * Data::Dumper::Simple

Like Data::Dumper, but prints the variable name instead of just C<$VAR1>,
C<$VAR2>, C<$VAR3> and so on.  This makes debugging much easier.

=item * DBD::SQLite

If you do database work but you've never touched this module, you're missing
out.  No setup.  No configuration.  It's just I<there>.

=back

=head1 AUTHOR

Curtis "Ovid" Poe, <moc.oohay@eop_divo_sitruc>

Reverse the name to email me.
