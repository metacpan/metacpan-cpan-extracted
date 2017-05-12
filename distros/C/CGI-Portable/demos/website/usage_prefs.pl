my $rh_preferences = { 
	email_logs => 1,  # do we want to be sent daily reports?
	fn_dcm => 'date_counts_mailed.txt',  # our lock file to track mailings
	mailing => [  # keep different types of reports in own emails
		{
			filenames => 'env.txt',
			subject_unique => ' -- usage (env) to ',
		}, {
			filenames => 'site_vrp.txt',
			subject_unique => ' -- usage (page views) to ',
		}, {
			filenames => 'redirect_urls.txt',
			subject_unique => ' -- usage (external) to ',
		}, {
			filenames => [qw(
				ref_urls.txt ref_se_urls.txt 
				ref_se_keywords.txt ref_discards.txt
			)],
			subject_unique => ' -- usage (references) to ',
			erase_files => 1,  # start over listing each day
		},
	],
	env => {  # what misc info do we want to know (low value distrib)
		filename => 'env.txt',
		var_list => [qw(
			DOCUMENT_ROOT GATEWAY_INTERFACE HTTP_CONNECTION HTTP_HOST
			REQUEST_METHOD SCRIPT_FILENAME SCRIPT_NAME SERVER_ADMIN 
			SERVER_NAME SERVER_PORT SERVER_PROTOCOL SERVER_SOFTWARE
		)],
	},
	site => {  # which pages on our own site are viewed?
		filename => 'site_vrp.txt',
	},
	redirect => {  # which of our external links are followed?
		filename => 'redirect_urls.txt',
	},
	referrer => {  # what sites are referring to us?
		filename => 'ref_urls.txt',   # normal websites go here
		fn_search => 'ref_se_urls.txt',  # search engines go here
		fn_keywords => 'ref_se_keywords.txt',  # their keywords go here
		fn_discards => 'ref_discards.txt',  # uris we filter out
		discards => [qw(  # filter uri's we want to ignore
			^(?!http://)
			deja
			mail
		)],
		search_engines => {  # match domain with query param holding keywords
			alltheweb => 'query', # AllTheWeb
			altavista => 'q',     # Altavista
			'aj.com' => 'ask',    # Ask Jeeves
			aol => 'query',       # America Online
			'ask.com' => 'ask',   # Ask Jeeves
			askjeeves => 'ask',   # Ask Jeeves
			'c4.com' => 'searchtext', # C4
			'cs.com' => 'sterm',  # CompuServe
			dmoz => 'search',     # Mozilla Open Directory
			dogpile => 'q',       # DogPile
			excite => 's',        # Excite
			google => 'q',        # Google
			'goto.com' => 'keywords', # GoTo.com, Inc
			'icq.com' => 'query', # ICQ
			infogrid => 'search', # InfoGrid
			intelliseek => 'queryterm', # "Infrastructure For Intelligent Portals"
			iwon => 'searchfor',  # I Won
			looksmart => 'key',   # LookSmart
			lycos => 'query',     # Lycos
			mamma => 'query',     # "Mother of Search Engines"
			metacrawler => 'general', # MetaCrawler
			msn => ['q','mt'],    # Microsoft
			nbci => 'keyword',    # NBCi
			netscape => 'search', # Netscape
			ninemsn => 'q',       # nine msn
			northernlight => 'qr', # Northern Light Search
			'search.com' => 'q',  # CNET
			'searchalot' => 'search', # SearchALot
			snap => 'keyword',    # Microsoft
			webcrawler => 'search', # Webcrawler
			yahoo => 'p',         # Yahoo
		},
	},
};
