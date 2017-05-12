	package Bundle::Bugzilla;

$VERSION = '0.12';

1;

__END__

=head1 NAME

Bundle::Bugzilla - A bundle of the modules required for Bugzilla.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Bugzilla'>

=head1 CONTENTS

AppConfig 1.52

CGI 2.98

CGI::Carp

Data::Dumper

Date::Format 2.21

DBI 1.38

Bundle::DBD::mysql

File::Spec 0.84

File::Temp

Template 2.08

Text::Wrap

Mail::Mailer 1.67

Storable

MIME::Parser

MIME::Base64

=head1 DESCRIPTION

This bundle installs the prerequisites for Bugzilla.

After installing this bundle, it is recommended that you run the magic 
checksetup.pl script to check that all modules are in place and setup 
the tables in the database. Then, you will need to edit the file called 
'localconfig' with your settings. After this, log in to 
your installation and make yourself an account. Run checksetup.pl again 
and you will become the superuser for your bugzilla installation. 

Still confused? Read the information in the docs/ directory in the Bugzilla 
distribution for more information on the installation process.

=head1 AUTHOR

Zach Lipton, <zlipton@cpan.org>

