use Test::More tests => 13;

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter' );
}

diag( "Testing BioX::SeqUtils::Promoter $BioX::SeqUtils::Promoter::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Alignment' );
}

diag( "Testing BioX::SeqUtils::Promoter::Alignment $BioX::SeqUtils::Promoter::Alignment::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Annotations' );
}

diag( "Testing BioX::SeqUtils::Promoter::Annotations $BioX::SeqUtils::Promoter::Annotations::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Annotations::Base' );
}

diag( "Testing BioX::SeqUtils::Promoter::Annotations::Base $BioX::SeqUtils::Promoter::Annotations::Base::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Annotations::CG' );
}

diag( "Testing BioX::SeqUtils::Promoter::Annotations::CG $BioX::SeqUtils::Promoter::Annotations::CG::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Annotations::Consensus' );
}

diag( "Testing BioX::SeqUtils::Promoter::Annotations::Consensus $BioX::SeqUtils::Promoter::Annotations::Consensus::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Base' );
}

diag( "Testing BioX::SeqUtils::Promoter::Base $BioX::SeqUtils::Promoter::Base::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::SaveTypes' );
}

diag( "Testing BioX::SeqUtils::Promoter::SaveTypes $BioX::SeqUtils::Promoter::SaveTypes::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::SaveTypes::Base' );
}

diag( "Testing BioX::SeqUtils::Promoter::SaveTypes::Base $BioX::SeqUtils::Promoter::SaveTypes::Base::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::SaveTypes::RImage' );
}

diag( "Testing BioX::SeqUtils::Promoter::SaveTypes::RImage $BioX::SeqUtils::Promoter::SaveTypes::RImage::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::SaveTypes::Text' );
}

diag( "Testing BioX::SeqUtils::Promoter::SaveTypes::Text $BioX::SeqUtils::Promoter::SaveTypes::Text::VERSION" );


BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Sequence' );
}

diag( "Testing BioX::SeqUtils::Promoter::Sequence $BioX::SeqUtils::Promoter::Sequence::VERSION" );

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Sequences' );
}

diag( "Testing BioX::SeqUtils::Promoter::Sequences $BioX::SeqUtils::Promoter::Sequences::VERSION" );
