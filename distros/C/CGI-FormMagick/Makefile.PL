use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


WriteMakefile(
    'NAME'		=> 'CGI::FormMagick',
    'VERSION_FROM'	=> 'lib/CGI/FormMagick.pm', # finds $VERSION
    'PREREQ_PM'		=> { # e.g., Module::Name => 1.1
				Persistence::Object::Simple => 0.47,
				XML::Parser => 2.30,
				Text::Template => 1.40,
				Class::ParamParser => 1.0401,
				CGI::Persistent => 0.21,
                                Text::Iconv => 1.2,
                                Test::Inline    => 0.15,
                                Test::More      => 0.42,
                                I18N::LangTags  => 0.13,
                                Time::ParseDate => 100.01,

	# required for validation routines only.  I'm commenting them
	# out for now.
				# Geography::States => 1.3,
				# Locale::Country => 1.02,
			},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/CGI/FormMagick.pm', # retrieve abstract from module
       AUTHOR     => 'Mitel Networks Corp. <mitel@cpan.org>') : ()),

);

print "Generating embedded tests...\n";
open(MANIFEST, "MANIFEST");
foreach my $file (grep /\.pm$/, <MANIFEST>) {
	next if $file =~ m(L10N/..\.pm$);		# skip lexicon stubs
	chomp $file;
	my($module) = $file =~ m|^lib/(.*)\.pm$|;
	$module =~ s|/|-|g;
	system("pod2test $file t/embedded-$module.t");
}

#{
    #package MY;
    #sub top_targets {
        #my($self) = @_;
        #my $out = "POD2TEST_EXE = pod2test\n";
#
        #$out .= $self->SUPER::top_targets(@_);
        #$out =~ s/^(pure_all\b.*)/$1 testifypods/m;
#
        #$out .= "\n\ntestifypods : \n";
#
        #foreach my $pod (keys %{$self->{MAN1PODS}},
                         #keys %{$self->{MAN3PODS}})
        #{
	    #next if $pod =~ m(L10N/..\.pm$);		# skip lexicon stubs
            #(my $test = $pod) =~ s/\.(pm|pod)$//;
            #$test =~ s/^lib\W//;
            #$test =~ s/\W/-/;
            #$test = "embedded-$test.t";
            #$out .= "\t$self->{NOECHO}\$(POD2TEST_EXE) $pod t/$test \\\n";
        #}
#
        #return $out;
    #}
#}

