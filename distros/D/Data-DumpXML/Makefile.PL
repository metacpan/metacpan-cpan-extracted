use ExtUtils::MakeMaker;

WriteMakefile(
   NAME         => "Data::DumpXML",
   VERSION_FROM => "DumpXML.pm",
   PREREQ_PM    => {
		    'MIME::Base64'   => 2.00,
                    'XML::Parser'    => 2.00,
		    'Array::RefElem' => 0.01,
		   },
   dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
);
