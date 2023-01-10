package Bundle::DadaMail;

$VERSION = '0.0.17';

1;

__END__

=head1 NAME 

C<Bundle::DadaMail> - CPAN Bundle for CPAN modules require to run Dada Mail

=head1 SYNOPSIS

	perl -MCPAN -e 'install Bundle::DadaMail'

or similar CPAN module installer method

=head1 Description

C<Bundle::DadaMail> is a CPAN Bundle of all CPAN modules required to run Dada Mail. 

Some modules are shipped with the app itself. These modules are for the most part Pure Perl. You may not want to use the included perllib, so we suggest installing C<Bundle::DadaMail> instead and letting your usual perl sys admin tools handle things in whatever way you do that. 

Those modules are listed in, C<Bundle::DadaMail::IncludedInDistribution>. Installing this module will also install that bundle.

There are also optional modules that Dada Mail can utilize to extend its functionality. They are listed in, C<Bundle::DadaMailXXL> and installing C<Bundle::DadaMailXXL> will install the two bundles already mentioned.

=head2 Backend Details

Dada Mail supports running using SQLite, MySQL or PostgreSQL. This bundle only asks to install C<DBD::SQLite>. If you would like to run Dada Mail under a different backend, you will need to install those drivers separately. 

=head1 See Also

L<https://dadamailproject.com>

L<https://github.com/justingit/Bundle-DadaMail>

=head1 CONTENTS

Bundle::DadaMail::IncludedInDistribution

DBI

DBD::SQLite

JSON - actually required for Dada Mail - Pure Perl version included, but you probably want to use a faster version
