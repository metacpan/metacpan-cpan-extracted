# Song specific queries and formatting...
package Audio::DB::DataTypes::Song;

use strict;
use Audio::DB::Util::Rearrange;

# Data accesssors for song objects

sub artist       { return shift->{artist};       }
sub bitrate      { return shift->{bitrate};      }
sub album_id     { return shift->{album_id};     }
sub artist_id    { return shift->{artist_id};    }
sub channels     { return shift->{channels};     }
sub comment      { return shift->{comment};      }
sub duration     { return shift->{duration};     }
sub filename     { return shift->{filename};     }
sub filepath     { return shift->{filepath};     }
sub filesize     { return shift->{filesize};     }
sub fileformat   { return shift->{fileformat};   }
sub genre_id     { return shift->{genre_id};     }
sub lyrics       { return shift->{lyrics};       }
sub uber_playcount  { return shift->{uber_playcount};    }
sub uber_rating     { return shift->{uber_rating};       }
sub samplerate   { return shift->{samplerate};   }
sub seconds      { return shift->{seconds};      }
sub song_id      { return shift->{song_id};      }
sub title        { return shift->{title};        }
sub tagtypes     { return shift->{tagtypes};     }
sub track        { return shift->{track};        }
sub year         { return shift->{year};         }


1;
