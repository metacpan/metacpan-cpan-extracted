use 5.008001;
use strict;
use warnings;

package Data::Fake::Names;
# ABSTRACT: Fake name data generators

our $VERSION = '0.006';

use Exporter 5.57 qw/import/;

our @EXPORT = qw(
  fake_name
  fake_first_name
  fake_surname
);

my ( @male_first, @female_first, @surnames );
my ( $male_count, $female_count, $surname_count );

sub _female_first { return $female_first[ int( rand($female_count) ) ] }
sub _male_first   { return $male_first[ int( rand($male_count) ) ] }
sub _surname      { return $surnames[ int( rand($surname_count) ) ] }

#pod =func fake_name
#pod
#pod     $generator = fake_name();
#pod
#pod Returns a generator that provides a randomly selected name with
#pod first, middle and last name parts.
#pod
#pod =cut

sub fake_name {
    return sub {
        my $is_male = ( rand() < 0.5 );
        my @given = map { $is_male ? _male_first() : _female_first() } 1 .. 2;
        return join( " ", @given, _surname() );
    };
}

#pod =func fake_first_name
#pod
#pod     $generator = fake_first_name();
#pod
#pod Returns a generator that provides a randomly selected first name.
#pod It will be split 50/50 between male and female names.
#pod
#pod =cut

sub fake_first_name {
    return sub {
        my $is_male = ( rand() < 0.5 );
        return $is_male ? _male_first() : _female_first();
      }
}

#pod =func fake_surname
#pod
#pod     $generator = fake_surname();
#pod
#pod Returns a generator that provides a randomly selected surname.
#pod
#pod =cut

sub fake_surname {
    return sub { _surname() }
}

# first name data from 2013 US Social Security Administration

@male_first = qw(
  Noah Liam Jacob Mason William Ethan Michael Alexander Jayden Daniel
  Elijah Aiden James Benjamin Matthew Jackson Logan David Anthony
  Joseph Joshua Andrew Lucas Gabriel Samuel Christopher John Dylan
  Isaac Ryan Nathan Carter Caleb Luke Christian Hunter Henry Owen
  Landon Jack Wyatt Jonathan Eli Isaiah Sebastian Jaxon Julian
  Brayden Gavin Levi Aaron Oliver Jordan Nicholas Evan Connor Charles
  Jeremiah Cameron Adrian Thomas Robert Tyler Colton Austin Jace
  Angel Dominic Josiah Brandon Ayden Kevin Zachary Parker Blake Jose
  Chase Grayson Jason Ian Bentley Adam Xavier Cooper Justin Nolan
  Hudson Easton Jase Carson Nathaniel Jaxson Kayden Brody Lincoln
  Luis Tristan Damian Camden Juan Vincent Bryson Ryder Asher Carlos
  Jesus Micah Maxwell Mateo Alex Max Leo Elias Cole Miles Silas Bryce
  Eric Brantley Sawyer Declan Braxton Kaiden Colin Timothy Santiago
  Antonio Giovanni Hayden Diego Leonardo Bryan Miguel Roman Jonah
  Steven Ivan Kaleb Wesley Richard Jaden Victor Ezra Joel Edward
  Jayce Aidan Preston Greyson Brian Kaden Ashton Alan Patrick Kyle
  Riley George Jesse Jeremy Marcus Harrison Jude Weston Ryker
  Alejandro Jake Axel Grant Maddox Theodore Emmanuel Cayden Emmett
  Brady Bradley Gael Malachi Oscar Abel Tucker Jameson Caden Abraham
  Mark Sean Ezekiel Kenneth Gage Everett Kingston Nicolas Zayden King
  Bennett Calvin Avery Tanner Paul Kai Maximus Rylan Luca Graham Omar
  Derek Jayceon Jorge Peter Peyton Devin Collin Andres Jaiden Cody
  Zane Amir Corbin Francisco Xander Eduardo Conner Javier Jax Myles
  Griffin Iker Garrett Damien Simon Zander Seth Travis Charlie
  Cristian Trevor Zion Lorenzo Dean Gunner Chance Elliot Lukas Cash
  Elliott Israel Manuel Josue Jasper Keegan Finn Spencer Stephen
  Fernando Ricardo Mario Jeffrey Shane Clayton Reid Erick Cesar
  Paxton Martin Raymond Judah Trenton Johnny Andre Tyson Beau Landen
  Caiden Maverick Dominick Troy Kyler Hector Cruz Beckett Johnathan
  Donovan Edwin Kameron Marco Drake Edgar Holden Rafael Dante Jaylen
  Emiliano Waylon Andy Alexis Rowan Felix Drew Emilio Gregory Karter
  Brooks Dallas Lane Anderson Jared Skyler Angelo Shawn Aden Erik
  Dalton Fabian Sergio Milo Louis Titus Kendrick Braylon August
  Dawson Reed Emanuel Arthur Jett Leon Brendan Frank Marshall Emerson
  Desmond Derrick Colt Karson Messiah Zaiden Braden Amari Roberto
  Romeo Joaquin Malik Walter Brennan Pedro Knox Nehemiah Julius Grady
  Allen Ali Archer Kamden Dakota Maximiliano Ruben Quinn Barrett Tate
  Corey Adan Braylen Marcos Remington Phillip Kason Major Kellan
  Cohen Walker Gideon Taylor River Jayson Brycen Abram Cade Matteo
  Dillon Damon Dexter Kolton Phoenix Noel Brock Porter Philip Enrique
  Leland Ty Esteban Danny Jay Gerardo Keith Kellen Gunnar Armando
  Zachariah Orion Ismael Colby Pablo Ronald Atticus Trey Quentin
  Ryland Kash Raul Enzo Julio Darius Rodrigo Landyn Donald Bruce
  Jakob Kade Ari Keaton Albert Muhammad Rocco Solomon Rhett Cason
  Jaime Scott Chandler Mathew Maximilian Russell Dustin Ronan Tony
  Cyrus Jensen Hugo Saul Trent Deacon Davis Colten Malcolm Mohamed
  Devon Izaiah Randy Ibrahim Jerry Prince Tristen Alec Chris Dennis
  Clark Gustavo Mitchell Rory Jamison Leonel Finnegan Pierce Nash
  Kasen Khalil Darren Moses Issac Adriel Lawrence Braydon Jaxton
  Alberto Justice Curtis Larry Warren Zayne Yahir Jimmy Uriel Finley
  Nico Thiago Armani Jacoby Jonas Rhys Casey Tobias Frederick Jaxen
  Kobe Franklin Ricky Talon Ace Marvin Alonzo Arjun Jalen Alfredo
  Moises Sullivan Francis Case Brayan Alijah Arturo Lawson Raylan
  Mekhi Nikolas Carmelo Byron Nasir Reece Royce Sylas Ahmed Mauricio
  Beckham Roy Payton Raiden Korbin Maurice Ellis Aarav Johan Gianni
  Kayson Aldo Arian Isaias Jamari Kristopher Uriah Douglas Kane Milan
  Skylar Dorian Tatum Wade Cannon Quinton Bryant Toby Dane Sam Moshe
  Asa Mohammed Joe Kieran Roger Channing Daxton Ezequiel Orlando
  Matias Malakai Nathanael Zackary Boston Ahmad Dominik Lance Alvin
  Conor Odin Cullen Mohammad Deandre Benson Gary Blaine Carl Sterling
  Nelson Kian Salvador Luka Nikolai Nixon Niko Bowen Kyrie Brenden
  Callen Vihaan Luciano Terry Demetrius Raphael Ramon Xzavier Amare
  Rohan Reese Quincy Eddie Noe Yusuf London Hayes Jefferson Matthias
  Kelvin Terrance Madden Bentlee Layne Harvey Sincere Kristian Julien
  Melvin Harley Emmitt Neil Rodney Winston Hank Ayaan Ernesto Jeffery
  Alessandro Lucian Rex Wilson Mathias Memphis Princeton Santino Jon
  Tripp Lewis Trace Dax Eden Joey Nickolas Neymar Bruno Marc Crosby
  Cory Kendall Abdullah Allan Davion Hamza Soren Brentley Jasiah
  Edison Harper Tommy Morgan Zain Flynn Roland Theo Chad Lee Bobby
  Rayan Samson Brett Kylan Branson Bronson Ray Arlo Lennox Stanley
  Zechariah Kareem Micheal Reginald Alonso Casen Guillermo Leonard
  Augustus Tomas Billy Conrad Aryan Makai Elisha Westin Otto Adonis
  Jagger Keagan Dayton Leonidas Kyson Brodie Alden Aydin Valentino
  Harry Willie Yosef Braeden Marlon Terrence Lamar Shaun Aron Blaze
  Layton Duke Legend Jessie Terrell Clay Dwayne Felipe Kamari Gerald
  Kody Kole Maxim Omari Chaim Crew Lionel Vicente Bo Sage Rogelio
  Jermaine Gauge Will Emery Giovani Ronnie Elian Hendrix Javon Rayden
  Alexzander Ben Camron Jamarion Kolby Remy Jamal Urijah Jaydon Kyree
  Ariel Braiden Cassius Triston Jerome Junior Landry Wayne Killian
  Jamie Davian Lennon Samir Oakley Rene Ronin Tristian Darian
  Giancarlo Jadiel Amos Eugene Mayson Vincenzo Alfonso Brent Cain
  Callan Leandro Callum Darrell Atlas Fletcher Jairo Jonathon Kenny
  Tyrone Adrien Markus Thaddeus Zavier Marcel Marquis Misael Abdiel
  Draven Ishaan Lyric Ulises Jamir Marcelo Davin Bodhi Justus Mack
  Rudy Cedric Craig Frankie Javion Maxton Deshawn Jair Duncan Hassan
  Gibson Isiah Cayson Darwin Kale Kolten Lucca Kase Konner Konnor
  Randall Azariah Stefan Enoch Kymani Dominique Maximo Van Forrest
  Alvaro Gannon Jordyn Rolando Sonny Brice Coleman Yousef Aydan Ean
  Johnathon Quintin Semaj Cristopher Harlan Vaughn Zeke Axton Damion
  Jovanni Fisher Heath Ramiro Seamus Vance Yael Jadon Kamdyn Rashad
  Camdyn Jedidiah Santos Steve Chace Marley Brecken Kamryn Valentin
  Dilan Mike Krish Salvatore Brantlee Gilbert Turner Camren Franco
  Hezekiah Zaid Anders Deangelo Harold Joziah Mustafa Emory Jamar
  Reuben Royal Zayn Arnav Bently Gavyn Ares Ameer Juelz Rodolfo Titan
  Bridger Briggs Cortez Blaise Demarcus Rey Hugh Benton Giovanny
  Tristin Aidyn Jovani Jaylin Jorden Kaeden Clinton Efrain Kingsley
  Makhi Aditya Teagan Jericho Kamron Xavi Ernest Kaysen Zaire Deon
  Foster Lochlan Gilberto Gino Izayah Maison Miller Antoine Garrison
  Rylee Cristiano Dangelo Keenan Stetson Truman Brysen Jaycob Kohen
  Augustine Castiel Langston Magnus Osvaldo Reagan Sidney Tyree Yair
  Deegan Kalel Todd Alfred Anson Apollo Rowen Santana Ephraim Houston
  Jayse Leroy Pierre Tyrell Camryn Grey Yadiel Aaden Corban Denzel
  Jordy Kannon Branden Brendon Brenton Dario Jakobe Lachlan Thatcher
  Immanuel Camilo Davon Graeme Rocky Broderick Clyde Darien
);

@female_first = qw(
  Sophia Emma Olivia Isabella Ava Mia Emily Abigail Madison Elizabeth
  Charlotte Avery Sofia Chloe Ella Harper Amelia Aubrey Addison Evelyn
  Natalie Grace Hannah Zoey Victoria Lillian Lily Brooklyn Samantha Layla
  Zoe Audrey Leah Allison Anna Aaliyah Savannah Gabriella Camila Aria
  Kaylee Scarlett Hailey Arianna Riley Alexis Nevaeh Sarah Claire Sadie
  Peyton Aubree Serenity Ariana Genesis Penelope Alyssa Bella Taylor Alexa
  Kylie Mackenzie Caroline Kennedy Autumn Lucy Ashley Madelyn Violet Stella
  Brianna Maya Skylar Ellie Julia Sophie Katherine Mila Khloe Paisley
  Annabelle Alexandra Nora Melanie London Gianna Naomi Eva Faith Madeline
  Lauren Nicole Ruby Makayla Kayla Lydia Piper Sydney Jocelyn Morgan
  Kimberly Molly Jasmine Reagan Bailey Eleanor Alice Trinity Rylee Andrea
  Hadley Maria Brooke Mariah Isabelle Brielle Mya Quinn Vivian Natalia Mary
  Liliana Payton Lilly Eliana Jade Cora Paige Valentina Kendall Clara Elena
  Jordyn Kaitlyn Delilah Isabel Destiny Rachel Amy Mckenzie Gabrielle
  Brooklynn Katelyn Laila Aurora Ariel Angelina Aliyah Juliana Vanessa
  Adriana Ivy Lyla Sara Willow Reese Hazel Eden Elise Josephine Kinsley
  Ximena Jessica Londyn Makenzie Gracie Isla Michelle Valerie Kylee Melody
  Catherine Adalynn Jayla Alexia Valeria Adalyn Rebecca Izabella Alaina
  Margaret Alana Alivia Kate Luna Norah Kendra Summer Ryleigh Julianna
  Jennifer Lila Hayden Emery Stephanie Angela Fiona Daisy Presley Eliza
  Harmony Melissa Giselle Keira Kinley Alayna Alexandria Emilia Marley
  Arabella Emerson Adelyn Brynn Lola Leila Mckenna Aniyah Athena Genevieve
  Allie Gabriela Daniela Cecilia Rose Adrianna Callie Jenna Esther Haley
  Leilani Maggie Adeline Hope Jaylah Amaya Maci Ana Juliet Jacqueline
  Charlie Lucia Tessa Camille Katie Miranda Lexi Makenna Jada Delaney
  Cassidy Alina Georgia Iris Ashlyn Kenzie Megan Anastasia Paris Shelby
  Jordan Danielle Lilliana Sienna Teagan Josie Angel Parker Mikayla Brynlee
  Diana Chelsea Kathryn Erin Annabella Kaydence Lyric Arya Madeleine
  Kayleigh Vivienne Sabrina Cali Raelynn Leslie Kyleigh Ayla Nina Amber
  Daniella Finley Olive Miriam Dakota Elliana Juliette Noelle Alison Amanda
  Alessandra Evangeline Phoebe Bianca Christina Yaretzi Raegan Kelsey Lilah
  Fatima Kiara Elaina Cadence Nyla Addyson Giuliana Alondra Gemma Ashlynn
  Carly Kyla Alicia Adelaide Laura Allyson Charlee Nadia Mallory Heaven
  Cheyenne Ruth Tatum Lena Ainsley Amiyah Journey Malia Haylee Veronica
  Eloise Myla Mariana Jillian Joanna Madilyn Baylee Selena Briella Sierra
  Rosalie Gia Briana Talia Abby Heidi Annie Jane Maddison Kira Carmen
  Lucille Harley Macy Skyler Kali June Elsie Kamila Adelynn Arielle Kelly
  Scarlet Rylie Haven Marilyn Aubrie Kamryn Kara Hanna Averie Marissa Jayda
  Jazmine Camryn Everly Jazmin Lia Karina Maliyah Miley Bethany Mckinley
  Jayleen Esmeralda Macie Aleah Catalina Nayeli Daphne Janelle Camilla
  Madelynn Kyra Addisyn Aylin Julie Caitlyn Sloane Gracelyn Elle Helen
  Michaela Serena Lana Angelica Raelyn Nylah Karen Emely Bristol Sarai
  Alejandra Brittany Vera April Francesca Logan Rowan Skye Sasha Carolina
  Kassidy Miracle Ariella Tiffany Itzel Justice Ada Brylee Jazlyn Dahlia
  Julissa Kaelyn Savanna Kennedi Anya Viviana Cataleya Jayden Sawyer Holly
  Kaylie Blakely Kailey Jimena Melany Emmalyn Guadalupe Sage Annalise
  Cassandra Madisyn Anabelle Kaylin Amira Crystal Elisa Caitlin Lacey
  Rebekah Celeste Danna Marlee Gwendolyn Joselyn Karla Joy Audrina Janiyah
  Anaya Malaysia Annabel Kadence Zara Imani Maeve Priscilla Phoenix Aspen
  Katelynn Dylan Eve Jamie Lexie Jaliyah Kailyn Lilian Braelyn Angie Lauryn
  Cynthia Emersyn Lorelei Monica Alanna Brinley Sylvia Journee Nia Aniya
  Breanna Fernanda Lillie Amari Charley Lilyana Luciana Raven Kaliyah
  Emilee Anne Bailee Hallie Zariah Bridget Annika Gloria Zuri Madilynn Elsa
  Nova Kiley Johanna Liberty Rosemary Aleena Courtney Madalyn Aryanna
  Tatiana Angelique Harlow Leighton Hayley Skyla Kenley Tiana Dayana
  Evelynn Selah Helena Blake Virginia Cecelia Nathalie Jaycee Danica Dulce
  Gracelynn Ember Evie Anika Emilie Erica Tenley Anabella Liana Cameron
  Braylee Aisha Charleigh Hattie Leia Lindsey Marie Regina Isis Alyson
  Anahi Elyse Felicity Jaelyn Amara Natasha Samara Lainey Daleyza Miah
  Melina River Amani Aileen Jessie Whitney Beatrice Caylee Greta Jaelynn
  Milan Millie Lea Marina Kaylynn Kenya Mariam Amelie Kaia Maleah Ally
  Colette Elisabeth Dallas Erika Karlee Alayah Alani Farrah Bria Madalynn
  Mikaela Adelina Amina Cara Jaylynn Leyla Nataly Braelynn Kiera Laylah
  Paislee Desiree Malaya Azalea Kensley Shiloh Brenda Lylah Addilyn Amiya
  Amya Maia Irene Ryan Jasmin Linda Adele Matilda Emelia Emmy Juniper Saige
  Ciara Estrella Jaylee Jemma Meredith Myah Rosa Teresa Yareli Kimber
  Madyson Claudia Maryam Zoie Kathleen Mira Paityn Isabela Perla Sariah
  Sherlyn Paola Shayla Winter Mae Simone Laney Pearl Ansley Jazlynn
  Patricia Aliana Brenna Armani Giana Lindsay Natalee Lailah Siena Nancy
  Raquel Willa Lilianna Frances Halle Janessa Kynlee Tori Leanna Bryanna
  Ellen Alma Lizbeth Wendy Chaya Christine Elianna Mabel Clarissa Kassandra
  Mollie Charli Diamond Kristen Coraline Mckayla Ariah Arely Blair Edith
  Joslyn Hailee Jaylene Chanel Alia Reyna Casey Clare Dana Alena Averi
  Alissa Demi Aiyana Leona Kailee Karsyn Kallie Taryn Corinne Rayna Asia
  Jaylin Noemi Carlee Abbigail Aryana Ayleen Eileen Livia Lillianna Mara
  Danika Mina Aliya Paloma Aimee Kaya Kora Tabitha Denise Hadassah Kayden
  Monroe Briley Celia Sandra Elaine Hana Jolie Kristina Myra Milana Lisa
  Renata Zariyah Adrienne America Emmalee Zaniyah Celine Cherish Jaida
  Kimora Mariyah Avah Nola Iliana Chana Cindy Janiya Carolyn Marisol Maliah
  Galilea Kiana Milania Alaya Bryn Emory Lorelai Jocelynn Yamileth Martha
  Jenny Keyla Alyvia Wren Dorothy Jordynn Amirah Nathaly Taliyah Zaria
  Deborah Elin Rylan Aubrianna Yasmin Julianne Zion Roselyn Salma Ivanna
  Joyce Paulina Lilith Saniyah Janae Aubrielle Ayanna Henley Sutton Aurelia
  Lesly Remi Britney Heather Barbara Bryleigh Emmalynn Kaitlynn Elliot
  Milena Susan Ariyah Kyndall Paula Thalia Aubri Kaleigh Tegan Yaritza
  Angeline Mercy Kairi Kourtney Krystal Carla Carter Mercedes Alannah Lina
  Sonia Kenia Everleigh Ivory Sloan Abril Alisha Katalina Carlie Lara
  Laurel Scarlette Carley Dixie Miya Micah Regan Samiyah Charlize Sharon
  Rosie Aviana Aleigha Gwyneth Sky Estella Hadlee Luz Patience Temperance
  Ingrid Raina Libby Jurnee Zahra Belen Jewel Anabel Marianna Renee Rory
  Elliott Karlie Saylor Deanna Freya Lilia Marjorie Sidney Tara Azaria
  Campbell Kai Ann Destinee Ariya Lilyanna Avianna Macey Shannon Lennon
  Saniya Haleigh Jolene Liv Oakley Esme Hunter Aliza Amalia Annalee Evalyn
  Giavanna Karis Kaylen Rayne Audriana Emerie Giada Harlee Kori Margot
  Abrielle Ellison Gwen Moriah Wynter Alisson Belinda Cristina Lillyana
  Neriah Rihanna Tamia Rivka Annabell Araceli Ayana Emmaline Giovanna Kylah
  Kailani Karissa Nahla Zainab Devyn Karma Marleigh Meadow India Kaiya
  Sarahi Audrianna Natalya Bayleigh Estelle Kaidence Kaylyn Magnolia
  Princess Avalyn Ireland Jayde Roxanne Alaysia Amia Astrid Karly Dalilah
  Makena Penny Ryann Charity Judith Kenna Tess Tinley Collins
);

# surname data from 1990 US Census

@surnames = qw(
  Smith Johnson Williams Jones Brown Davis Miller Wilson Moore Taylor
  Anderson Thomas Jackson White Harris Martin Thompson Garcia Martinez
  Robinson Clark Rodriguez Lewis Lee Walker Hall Allen Young Hernandez King
  Wright Lopez Hill Scott Green Adams Baker Gonzalez Nelson Carter Mitchell
  Perez Roberts Turner Phillips Campbell Parker Evans Edwards Collins Stewart
  Sanchez Morris Rogers Reed Cook Morgan Bell Murphy Bailey Rivera Cooper
  Richardson Cox Howard Ward Torres Peterson Gray Ramirez James Watson Brooks
  Kelly Sanders Price Bennett Wood Barnes Ross Henderson Coleman Jenkins
  Perry Powell Long Patterson Hughes Flores Washington Butler Simmons Foster
  Gonzales Bryant Alexander Russell Griffin Diaz Hayes Myers Ford Hamilton
  Graham Sullivan Wallace Woods Cole West Jordan Owens Reynolds Fisher Ellis
  Harrison Gibson Mcdonald Cruz Marshall Ortiz Gomez Murray Freeman Wells
  Webb Simpson Stevens Tucker Porter Hunter Hicks Crawford Henry Boyd Mason
  Morales Kennedy Warren Dixon Ramos Reyes Burns Gordon Shaw Holmes Rice
  Robertson Hunt Black Daniels Palmer Mills Nichols Grant Knight Ferguson
  Rose Stone Hawkins Dunn Perkins Hudson Spencer Gardner Stephens Payne
  Pierce Berry Matthews Arnold Wagner Willis Ray Watkins Olson Carroll Duncan
  Snyder Hart Cunningham Bradley Lane Andrews Ruiz Harper Fox Riley Armstrong
  Carpenter Weaver Greene Lawrence Elliott Chavez Sims Austin Peters Kelley
  Franklin Lawson Fields Gutierrez Ryan Schmidt Carr Vasquez Castillo Wheeler
  Chapman Oliver Montgomery Richards Williamson Johnston Banks Meyer Bishop
  Mccoy Howell Alvarez Morrison Hansen Fernandez Garza Harvey Little Burton
  Stanley Nguyen George Jacobs Reid Kim Fuller Lynch Dean Gilbert Garrett
  Romero Welch Larson Frazier Burke Hanson Day Mendoza Moreno Bowman Medina
  Fowler Brewer Hoffman Carlson Silva Pearson Holland Douglas Fleming Jensen
  Vargas Byrd Davidson Hopkins May Terry Herrera Wade Soto Walters Curtis
  Neal Caldwell Lowe Jennings Barnett Graves Jimenez Horton Shelton Barrett
  Obrien Castro Sutton Gregory Mckinney Lucas Miles Craig Rodriquez Chambers
  Holt Lambert Fletcher Watts Bates Hale Rhodes Pena Beck Newman Haynes
  Mcdaniel Mendez Bush Vaughn Parks Dawson Santiago Norris Hardy Love Steele
  Curry Powers Schultz Barker Guzman Page Munoz Ball Keller Chandler Weber
  Leonard Walsh Lyons Ramsey Wolfe Schneider Mullins Benson Sharp Bowen
  Daniel Barber Cummings Hines Baldwin Griffith Valdez Hubbard Salazar Reeves
  Warner Stevenson Burgess Santos Tate Cross Garner Mann Mack Moss Thornton
  Dennis Mcgee Farmer Delgado Aguilar Vega Glover Manning Cohen Harmon
  Rodgers Robbins Newton Todd Blair Higgins Ingram Reese Cannon Strickland
  Townsend Potter Goodwin Walton Rowe Hampton Ortega Patton Swanson Joseph
  Francis Goodman Maldonado Yates Becker Erickson Hodges Rios Conner Adkins
  Webster Norman Malone Hammond Flowers Cobb Moody Quinn Blake Maxwell Pope
  Floyd Osborne Paul Mccarthy Guerrero Lindsey Estrada Sandoval Gibbs Tyler
  Gross Fitzgerald Stokes Doyle Sherman Saunders Wise Colon Gill Alvarado
  Greer Padilla Simon Waters Nunez Ballard Schwartz Mcbride Houston
  Christensen Klein Pratt Briggs Parsons Mclaughlin Zimmerman French Buchanan
  Moran Copeland Roy Pittman Brady Mccormick Holloway Brock Poole Frank Logan
  Owen Bass Marsh Drake Wong Jefferson Park Morton Abbott Sparks Patrick
  Norton Huff Clayton Massey Lloyd Figueroa Carson Bowers Roberson Barton
  Tran Lamb Harrington Casey Boone Cortez Clarke Mathis Singleton Wilkins
  Cain Bryan Underwood Hogan Mckenzie Collier Luna Phelps Mcguire Allison
  Bridges Wilkerson Nash Summers Atkins Wilcox Pitts Conley Marquez Burnett
  Richard Cochran Chase Davenport Hood Gates Clay Ayala Sawyer Roman Vazquez
  Dickerson Hodge Acosta Flynn Espinoza Nicholson Monroe Wolf Morrow Kirk
  Randall Anthony Whitaker Oconnor Skinner Ware Molina Kirby Huffman Bradford
  Charles Gilmore Dominguez Oneal Bruce Lang Combs Kramer Heath Hancock
  Gallagher Gaines Shaffer Short Wiggins Mathews Mcclain Fischer Wall Small
  Melton Hensley Bond Dyer Cameron Grimes Contreras Christian Wyatt Baxter
  Snow Mosley Shepherd Larsen Hoover Beasley Glenn Petersen Whitehead Meyers
  Keith Garrison Vincent Shields Horn Savage Olsen Schroeder Hartman Woodard
  Mueller Kemp Deleon Booth Patel Calhoun Wiley Eaton Cline Navarro Harrell
  Lester Humphrey Parrish Duran Hutchinson Hess Dorsey Bullock Robles Beard
  Dalton Avila Vance Rich Blackwell York Johns Blankenship Trevino Salinas
  Campos Pruitt Moses Callahan Golden Montoya Hardin Guerra Mcdowell Carey
  Stafford Gallegos Henson Wilkinson Booker Merritt Miranda Atkinson Orr
  Decker Hobbs Preston Tanner Knox Pacheco Stephenson Glass Rojas Serrano
  Marks Hickman English Sweeney Strong Prince Mcclure Conway Walter Roth
  Maynard Farrell Lowery Hurst Nixon Weiss Trujillo Ellison Sloan Juarez
  Winters Mclean Randolph Leon Boyer Villarreal Mccall Gentry Carrillo Kent
  Ayers Lara Shannon Sexton Pace Hull Leblanc Browning Velasquez Leach Chang
  House Sellers Herring Noble Foley Bartlett Mercado Landry Durham Walls Barr
  Mckee Bauer Rivers Everett Bradshaw Pugh Velez Rush Estes Dodson Morse
  Sheppard Weeks Camacho Bean Barron Livingston Middleton Spears Branch
  Blevins Chen Kerr Mcconnell Hatfield Harding Ashley Solis Herman Frost
  Giles Blackburn William Pennington Woodward Finley Mcintosh Koch Best
  Solomon Mccullough Dudley Nolan Blanchard Rivas Brennan Mejia Kane Benton
  Joyce Buckley Haley Valentine Maddox Russo Mcknight Buck Moon Mcmillan
  Crosby Berg Dotson Mays Roach Church Chan Richmond Meadows Faulkner Oneill
  Knapp Kline Barry Ochoa Jacobson Gay Avery Hendricks Horne Shepard Hebert
  Cherry Cardenas Mcintyre Whitney Waller Holman Donaldson Cantu Terrell
  Morin Gillespie Fuentes Tillman Sanford Bentley Peck Key Salas Rollins
  Gamble Dickson Battle Santana Cabrera Cervantes Howe Hinton Hurley Spence
  Zamora Yang Mcneil Suarez Case Petty Gould Mcfarland Sampson Carver Bray
  Rosario Macdonald Stout Hester Melendez Dillon Farley Hopper Galloway Potts
  Bernard Joyner Stein Aguirre Osborn Mercer Bender Franco Rowland Sykes
  Benjamin Travis Pickett Crane Sears Mayo Dunlap Hayden Wilder Mckay Coffey
  Mccarty Ewing Cooley Vaughan Bonner Cotton Holder Stark Ferrell Cantrell
  Fulton Lynn Lott Calderon Rosa Pollard Hooper Burch Mullen Fry Riddle Levy
  David Duke Odonnell Guy Michael Britt Frederick Daugherty Berger Dillard
  Alston Jarvis Frye Riggs Chaney Odom Duffy Fitzpatrick Valenzuela Merrill
  Mayer Alford Mcpherson Acevedo Donovan Barrera Albert Cote Reilly Compton
  Raymond Mooney Mcgowan Craft Cleveland Clemons Wynn Nielsen Baird Stanton
  Snider Rosales Bright Witt Stuart Hays Holden Rutledge Kinney Clements
  Castaneda Slater Hahn Emerson Conrad Burks Delaney Pate Lancaster Sweet
  Justice Tyson Sharpe Whitfield Talley Macias Irwin Burris Ratliff Mccray
  Madden Kaufman Beach Goff Cash Bolton Mcfadden Levine Good Byers Kirkland
  Kidd Workman Carney Dale Mcleod Holcomb England Finch Head Burt Hendrix
  Sosa Haney Franks Sargent Nieves Downs Rasmussen Bird Hewitt Lindsay Le
  Foreman Valencia Oneil Delacruz Vinson Dejesus Hyde Forbes Gilliam Guthrie
  Wooten Huber Barlow Boyle Mcmahon Buckner Rocha Puckett Langley Knowles
  Cooke Velazquez Whitley Noel Vang
);

$male_count    = @male_first;
$female_count  = @female_first;
$surname_count = @surnames;


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Fake::Names - Fake name data generators

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Data::Fake::Names;

    fake_first_name()->();  # Fred, Mary, etc.
    fake_surname()->();     # Cooke, Boyle, etc.
    fake_name()->();        # Fred James Cooke, etc.

=head1 DESCRIPTION

This module provides fake data generators for person names.  Currently,
all names are English ASCII, drawn from US government "top names" lists.

All functions are exported by default.

=head1 FUNCTIONS

=head2 fake_name

    $generator = fake_name();

Returns a generator that provides a randomly selected name with
first, middle and last name parts.

=head2 fake_first_name

    $generator = fake_first_name();

Returns a generator that provides a randomly selected first name.
It will be split 50/50 between male and female names.

=head2 fake_surname

    $generator = fake_surname();

Returns a generator that provides a randomly selected surname.

=for Pod::Coverage BUILD

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
