package Business::LetterWriter;

use strict;
use warnings;
use JSON;
use OpenAPI::Client::OpenAI;
use Archive::Zip;
use XML::Twig;

our $VERSION = '0.09';

sub get_one_answer_from_new_llm {
    my ($request, $body_builder) = @_;
    
    $body_builder //= sub {
        return {
            model    => 'gpt-4o',
            messages => [ { role => 'user', content => $request } ],
            temperature => 0,
            max_tokens  => 1000,
        };
    };

    my $client = OpenAPI::Client::OpenAI->new();
    my $body = $body_builder->($request);
    my $tx = $client->createChatCompletion({ body => $body });

    my $response_data = $tx->res->json;
    my $raw_response = $response_data->{choices}[0]{message}{content};
    if ($raw_response =~ /({.*})/s) {
        return $1;
    }
    die "Unexpected response format in get_one_answer_from_new_llm.\n";
}

sub get_hashref_from_template_file{
	my $template_fname = shift;
	open my $template_fh, "<:encoding(UTF-8)", $template_fname  or die $!;
	my $template = do{local $/; <$template_fh>};
	my @arr = split /\n{2}/, $template;
	my $counter = 1;
	my %return_hash = ();
	foreach my $para (@arr){
		my $key = "paragraph_" . $counter++;
		$return_hash{$key} = $para;
	}
	return \%return_hash;
}

sub out_parts{
	my $text_hashref = shift;
	my $parms = shift;
	my $fn = $parms->{outfn};
	my $preserved_parts = $parms->{preserved_parts};
	open my $outfh, ">:encoding(UTF-8)", $fn  or die $!;
	foreach my $key (qw(paragraph_1 paragraph_2 paragraph_3 paragraph_4 paragraph_5 paragraph_6)){
		print $outfh $text_hashref->{$key}, "\n\n";
		# print $text_hashref->{$key}, "\n\n";
	}
	close $outfh;
}

sub signature{
    return "John Doe";
}


sub replace_in_docx{
	my $input_docx  = shift;
	my $output_docx = shift;
	my $replacement_hashref = shift;
	my $temp_dir    = "docx_contents_simple";

	# Step 1: Extract .docx contents
	my $zip = Archive::Zip->new();
	$zip->read($input_docx) == Archive::Zip::AZ_OK or die "Cannot read DOCX file";

	mkdir $temp_dir unless -d $temp_dir;
	$zip->extractTree('', "$temp_dir/");



	# Step 2: Load and edit word/document.xml
	my $xml_file = "$temp_dir/word/document.xml";
	my $doc=XML::Twig->new();    # create the twig
	$doc->parsefile( $xml_file); # build it

	# my %replacement_hash = ('{Address1}' => 'Egasse 66', '{Address2}' => 'Bern 3044');
	my %replacement_hash = %{$replacement_hashref};

	# Step 3: Merge text and replace content
	foreach my $p ($doc->findnodes('//w:p')) {  # Process each paragraph
		my @runs = $p->findnodes('.//w:t');     # Collect all text elements
		my $full_text = join('', map { $_->text } @runs);

		foreach my $placeholder (keys %replacement_hash) {
			# my $replacement = decode("UTF-8", $full_replacement_hash{$placeholder});
			# my $replacement = decode("UTF-8", $replacement_hash{$placeholder});
			my $replacement = $replacement_hash{$placeholder};
			$full_text =~ s/\{\Q$placeholder\E\}/$replacement/g;
		}
		
		# Update the XML: Replace text while keeping structure
		if (@runs) {
			$runs[0]->set_text($full_text);

			# Remove extra <w:t> elements
			for (my $i = 1; $i < @runs; $i++) {
				$runs[$i]->delete();
			}
		}
	}

	# Save changes
	open my $fh2, '>:utf8', $xml_file or die "Cannot write to XML file. $!" ;
	print $fh2 $doc->toString(1);
	close $fh2;

	# Step 4: Repackage back into a .docx file
	unlink $output_docx if -e $output_docx;
	my $new_zip = Archive::Zip->new();
	$new_zip->addTree($temp_dir, '');
	$new_zip->writeToFileNamed($output_docx) == Archive::Zip::AZ_OK or die "Failed to create new DOCX file";

	print "Editing complete. Output saved to $output_docx\n";
	
}

sub generate_meta_hashref_from_file{
	my $input_fn = shift;
	open my $fh, '<:utf8', $input_fn or die "Cannot open file: $!";
	my %data;
	while (<$fh>) {
		chomp;
		my ($key, $value) = split /:/, $_, 2;
		next unless defined $key && defined $value;
		$data{"$key"} = $value;
	}
	close $fh;
	return \%data;
}

=pod
    USAGE:
        use strict;
        use JSON;
        use lib '../Business-LetterWriter/lib/';
        use Business::LetterWriter;

        my $template_href = Business::LetterWriter::get_hashref_from_template_file("./CL_TEMPLATE_DE.txt");

        my $json = JSON->new->utf8(0)->pretty(1);
        my $letter_template_json = $json->encode($template_href);

        my $request 
            = "Here is a template letter in the JSON format: " . $letter_template_json .
            " Tailor each part to make the whole letter friendier less formal and very short. Return the tailored version of the letter strictly in JSON format. Do not explain anything." ;
        my $llm_answer_raw = Business::LetterWriter::get_one_answer_from_new_llm($request);
        my $template_href = $json->decode($llm_answer_raw);
        my %parms = (outfn => "outtest.txt");
        Business::LetterWriter::out_parts($template_href, \%parms);

    USAGE:
        use strict;
        use JSON;
        use lib '../Business-LetterWriter/lib/';
        use Business::LetterWriter;

        my $template_href = Business::LetterWriter::get_hashref_from_template_file("./customer_req/LETTER_TEMPLATE_DE.txt");
        my $json = JSON->new->utf8(0)->pretty(1);
        my $letter_template_json = $json->encode($template_href);

        my $customer_req_fn = "./customer_req/requirement_1.txt";
        open my $customer_req_fh, "<:encoding(UTF-8)", $customer_req_fn;
        my $customer_req_text = do{local $/; <$customer_req_fh>};

        # binmode(STDOUT, ":encoding(UTF-8)");  # stdout is UTF-8
        # print $customer_req;
        # exit;

        my $request 
            = "Here is a template letter in the JSON format: " . $letter_template_json .
            "Here is requirement of the company: " . $customer_req_text .
            " Tailor each part of the template letter to make the whole letter fit to the customer requirement. Return the tailored version of the letter strictly in JSON format. Do not explain anything." ;

        my $llm_answer_raw = Business::LetterWriter::get_one_answer_from_new_llm($request);

        my $template_href = $json->decode($llm_answer_raw);

        # Business::LetterWriter::out_parts($template_href, {outfn => "TAILORED_VERSION.txt"});
        my $metha_file_path_name = "./Customers/MyCustomer/META.txt";
        my $address_hashref = Business::LetterWriter::generate_meta_hashref_from_file($metha_file_path_name);
        my %combined_hash = ( %{$address_hashref} , %{$template_href});

        Business::LetterWriter::replace_in_docx("template.docx", "./my_results.docx", \%combined_hash);
=cut

1;
