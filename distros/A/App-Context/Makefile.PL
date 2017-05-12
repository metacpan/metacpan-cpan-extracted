
######################################################################
## File: $Id: Makefile.PL 13307 2009-09-11 13:59:44Z spadkins $
######################################################################

use ExtUtils::MakeMaker;

my @programs = (
    "bin/app",
    #"bin/mason",
    "bin/call",
    "bin/app-apache",
    #"bin/app-netserver",
);

%opts = (
    "NAME"        => "App-Context",
    "DISTNAME"    => "App-Context",
    "VERSION"     => "0.968",
    "EXE_FILES"   => [ @programs ],
    "PREREQ_PM"   => {
        # "Apache"                             => "0.01",  # used for mod_perl integration
        "App::Options"                       => "0.01",  # for loading a startup configuration file
        "CGI"                                => "0.01",  # tbd
        "CGI::Carp"                          => "0.01",  # tbd
        "Class::Data::Inheritable"           => "0.01",  # [prereq for Exception::Class]
        "Compress::Zlib"                     => "0.01",  # for compressed serialization and browser responses
        "Data::Dumper"                       => "0.01",  # used for debugging
        "Date::Parse"                        => "0.01",  # date support
        "Date::Format"                       => "0.01",  # date support
        "Devel::StackTrace"                  => "0.01",  # [prereq for Exception::Class]
        "Digest::SHA"                        => "0.01",  # tbd
        "Exception::Class"                   => "0.01",  # allows exception hierarchies
        "HTTP::Status"                       => "0.01",  # tbd
        "IO::Handle"                         => "0.01",  # tbd
        "IO::Socket"                         => "0.01",  # tbd
        "IO::Socket::INET"                   => "0.01",  # tbd
        "MIME::Base64"                       => "2.1",   # used for turning binary (serialized?) data into text (Sessions)
        "Pod::Checker"                       => "0.01",  # tbd
        # "POE"                                => "0.01",  # tbd
        # "POE::Component::IKC"                => "0.01",  # tbd
        # "POE::Component::Server::SimpleHTTP" => "0.01",  # tbd
        "POSIX"                              => "0.01",  # tbd
        "Socket"                             => "0.01",  # tbd
        "Storable"                           => "0.01",  # used for serialization everywhere
        "Sys::Hostname"                      => "0.01",  # tbd
        "Test::More"                         => "0.01",  # tbd
        "Time::HiRes"                        => "0.01",  # tbd
        "XML::Simple"                        => "0.01",  # tbd
        "YAML"                               => "0.01",  # tbd
    },
);

######################################################################
# MAKE THE MAKEFILE
######################################################################

WriteMakefile(%opts);

sub MY::postamble {
    return <<EOF;

install ::
	@\$(RM_F) "\$(PREFIX)/cgi-bin/app"
	@\$(CP) "\$(PREFIX)/bin/app" "\$(PREFIX)/cgi-bin/app"

EOF
}

