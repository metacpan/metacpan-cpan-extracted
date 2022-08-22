package Bundle::DadaMail::IncludedInDistribution;

$VERSION = '0.0.2';

1;

__END__

=head1 NAME 

C<Bundle::DadaMail::IncludedInDistribution> -  Bundle of CPAN modules used in Dada Mail that are included within the distribution.

=head1 SYNOPSIS

	perl -MCPAN -e 'install Bundle::DadaMail::IncludedInDistro'

or similar CPAN module installer method

=head1 Description

Dada Mail is a self-hosted mailing list manager. 

C<Bundle::DadaMail::IncludedInDistribution> is a CPAN Bundle of (most) all CPAN modules used by Dada Mail that are also included within the distribution. 

Portability and easy of installation are two big goals of the Dada Mail project. Dada Mail requires other CPAN modules to run, but those are NOT listed in this Bundle. See, C<Bundle::DadaMail>. We assume these modules will be available in the Perl ecosystem, but that's obviously not always the case. System requirements to run Dada Mail are listed here: 

L<https://dadamailproject.com/d/requirements.pod.html>
 
The included perllib that's created is massaged slightly to remove any platform-specific code. 

Optional modules that Dada Mail can utilize to extend its functionality are listed in, C<Bundle::DadaMailXXL>.  

These CPAN modules are bundled to make installing the app easier to non-developers. 

In the past, (Dada Mail was initially written in 1999) the modules included were not well documented, so this is an attempt to document which modules are included, and have a way to keep them up to date. 


=head1 Future Goals 

Because of the long history of the app, several now questionable module selections have been made, mostly where several modules provide the same/similar capabilities - example using C<CGI> and C<CGI::Lite>; some modules seem to provide capabilities that are actual in core, like: C<Digest::SHA::PurePerl>, and some modules may not need to be listed, as their simply prerequsites to other modules, and will be installed anyways, like: C<Class::Accessor>. One goal is to straighten that all out.

Removing the included Perl library from the app (found in, dada/DADA/perllib of the distribution) and installing this Bundle should be a reasonagble thing to do. In the future, it's a goal to have this as an option for the app upon installation/upgrade. 


=head1 See Also

L<https://dadamailproject.com>

L<https://github.com/justingit/dada-mail/>

L<https://github.com/justingit/Bundle-DadaMail-IncludedInDistribution>

=head1 CONTENTS

Authen::SASL

Best

Bundle::libnet

CGI

CGI::Carp

CGI::Application

CGI::Application::Plugin::RateLimit

CGI::Lite - used for kcfinder_session

CGI::Session

CGI::Session::ExpireSessions

Class::Accessor  - prereq to something

Class::Accessor::Chained::Fast - prereq to something

Convert::UU

Crypt::CipherSaber

Data::Google::Visualization::DataTable

Data::Page - prereq to DataPageset

Date::Format - prereq to something

DataPageset

Digest::SHA::PurePerl - weird 'cause Digest::SHA is core

Email::Address

Email::Find - pulls in Net::DNS :|

# Email::Valid  - doesn't work with v5.10.1

RJBS/Email-Valid-1.202.tar.gz # This does work with 5.10.1 - This isn't something we need to deal with in the CPAN Bundle tho

Exporter::Lite - prereq to something

File::Copy::Recursive - used in the installer 

File::Find::Rule - used for the Perl connector in KCFInder

File::ReadBackwards

File::Slurp - only used in Core5Filemanager - should be modified to not use 

File::Slurper

Geo::IP::PurePerl

Google::reCAPTCHA::v3

HTML::Entities::Numbered

HTML::FillInForm::Lite

HTML::FromText

HTML::Menu::Select

HTML::Tagset

HTML::Template

HTML::Tiny

Data::Pageset

HTTP::Date

JSON - but only the PP ver

LWP

Mail::DeliveryStatus::BounceParser

Mail::Address

Mail::Verp

MIME::EncWords

MIME::Base64::Perl

MIME::Tools

Number::Bytes::Human

Parse::RecDescent

Text::Balanced

PHP::Session

Text::CSV 

Text::FrontMatter::YAML

Text::Markdown

Text::Tabs

Text::Wrap - most likely gets pulled by something else. 

Time::Local - should be in core

Time::Piece::MySQL

Try::Tiny - prereq to something 

URI - prereq to something 

URI::Escape - prereq to something 

URI::Find

URI::GoogleChart - used for the fancy charts Dada Mail's Tracker plugin uses. 

URI::QueryParam - used by AWS::Signature4

YAML::Tiny
