package Business::EDI::CodeList::ItemCharacteristicCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7081;}
my $usage       = 'B';

# 7081  Item characteristic code                                [B]
# Desc: Code specifying the characteristic of an item.
# Repr: an..3

my %code_hash = (
'1' => [ 'Certificate of conformity',
    'Product in conformity with specifications.' ],
'2' => [ 'General product form',
    'Description of general product form.' ],
'3' => [ 'Ship to stock',
    'Product without quality control when received.' ],
'4' => [ 'Finish',
    'Description of the finish required/available on the product.' ],
'5' => [ 'End use application',
    'Description of what the end use application of the product will be.' ],
'6' => [ 'Construction method',
    'Description of the method of construction.' ],
'7' => [ 'Generic drug',
    'A drug name specially given in order that it may be freely used without legal restriction.' ],
'8' => [ 'Product',
    'The characteristic of a product.' ],
'9' => [ 'Sub-product',
    'Description of a sub-product.' ],
'10' => [ 'Grain direction',
    'Specifies the direction of the grain of the product.' ],
'11' => [ 'Customs specifications',
    'Item characteristic is described following Customs specifications.' ],
'12' => [ 'Type and/or process',
    'Description of the type and/or process involved in making the product. E.g. in steel, description of the steelmaking process.' ],
'13' => [ 'Quality',
    'The degree of excellence of a thing.' ],
'14' => [ 'Surface condition',
    'Description of the surface condition (e.g. roughness) of the product.' ],
'15' => [ 'Heat treat/anneal',
    'Description of any heat treatment or annealing required/performed on the product.' ],
'16' => [ 'Size system',
    'A code identifying a size system, comprising a set of sizes.' ],
'17' => [ 'Coating',
    'Description of any special coating required/available on the product.' ],
'18' => [ 'Surface treatment, chemical',
    'Description of any chemical surface treatment required/performed on the product.' ],
'19' => [ 'Surface treatment, mechanical',
    'Description of any mechanical surface treatment required/performed on the product.' ],
'20' => [ 'Transfer capacity type',
    'Type of transfer capacity.' ],
'21' => [ 'Forming',
    'Description of any forming required/performed on the product.' ],
'22' => [ 'Edge treatment',
    'Description of any special edge treatment required/performed on the product.' ],
'23' => [ 'Welds/splices',
    'Description of any special welds and or splices required/performed on the product.' ],
'24' => [ 'Control item',
    'Security relevant product with special quality control and control documentation prescriptions.' ],
'25' => [ 'End treatment',
    'Description of any special treatment required/performed on the ends the product.' ],
'26' => [ 'Ship to line',
    "Product without quality control at customer's, and packed according production needs." ],
'27' => [ 'Material description',
    'Description of material used to manufacture a product.' ],
'28' => [ 'Test sample frequency',
    'Indication of test sample frequency. Used when ordering special testing requirements on a product.' ],
'29' => [ 'Electricity exchange type',
    'Type of electricity exchange.' ],
'30' => [ 'Test sample direction',
    'Description of test sample direction. Used when ordering special testing requirements on a product.' ],
'31' => [ 'European Community risk class',
    'European community classification "CE" indicating the safety risk of an article.' ],
'32' => [ 'Type of test/inspection',
    'Description of type of test or inspection. Used to order special tests to be performed on the product.' ],
'33' => [ 'Electricity production type',
    'The type of electricity production.' ],
'34' => [ 'Hydrological data',
    "The properties of the earth's water in relation to land." ],
'35' => [ 'Colour',
    'Description of the colour required/available on the product.' ],
'36' => [ 'Electricity consumption type',
    'The way electricity is consumed.' ],
'37' => [ 'Weather data',
    'The characteristic described is the weather data.' ],
'38' => [ 'Grade',
    'Specification of the grade required/available for the product.' ],
'39' => [ 'Ancillary electricity service',
    'The characteristic described is the ancillary electricity service available or produced.' ],
'40' => [ 'Active substance',
    'Specification of an active substance in a product.' ],
'41' => [ 'Dangerous goods proper shipping name',
    'The proper shipping name of the dangerous goods as defined by the relevant authority.' ],
'42' => [ 'Fanciful name',
    'The fanciful name of the article.' ],
'43' => [ 'Twist',
    'Description of any special twisting requirements for the product.' ],
'44' => [ 'Further identifying characteristic',
    'Description of further identifying characteristic of a product which enables the product to be distinguished from any similar products.' ],
'45' => [ 'Private label name',
    'Describes the private label name of a product.' ],
'46' => [ 'Silhouette',
    'Describes the outline of the item.' ],
'47' => [ 'Warranty type description',
    'The warranty type description of the item.' ],
'48' => [ 'Yarn count',
    'Describes the fineness of the yarn in the cloth.' ],
'49' => [ 'Equipment',
    'Code indicating the category of equipment.' ],
'50' => [ 'Labour',
    'Characteristic being described is labour.' ],
'51' => [ 'Labour overtime',
    'Characteristic being described is overtime labour.' ],
'52' => [ 'Labour double time',
    'Characteristic being described is labour double time.' ],
'53' => [ 'Leased resource',
    'A code to identify the characteristics of a leased resource.' ],
'54' => [ 'Section profile',
    'Description of the section and profile of the product.' ],
'55' => [ 'Registered name',
    'The registered trademark or copyright name of the article.' ],
'56' => [ 'Special processing',
    'Description of any special processing requirements performed or required.' ],
'57' => [ 'Trade name',
    'The name of the article as commonly used by the industry sector where the article is traded and/or transported.' ],
'58' => [ 'Winding instructions',
    'Description of any special winding instructions for the product.' ],
'59' => [ 'Surface protection',
    'Description of the surface protection required/available for the product.' ],
'60' => [ 'Age',
    'The age of the object.' ],
'61' => [ 'New article',
    'The characteristic of a new item or commodity.' ],
'62' => [ 'Obsolete article',
    'The characteristic of a discarded item or commodity.' ],
'63' => [ 'Current article',
    'The characteristic of an item or commodity in use.' ],
'64' => [ 'Revised design',
    'The characteristic of a design that has been amended.' ],
'65' => [ 'Reinstated article',
    'The characteristic of an item or commodity that has been replaced in a former position.' ],
'66' => [ 'Current article spares',
    'The characteristic of an extra item or commodity in use.' ],
'67' => [ 'Balance out article',
    'The characteristic of an item or commodity for comparing or offsetting.' ],
'68' => [ 'Initial sample',
    'The characteristic of the beginning part or quantity intended to show what the whole is like.' ],
'69' => [ 'Field test',
    'First series of a new item to be tested by end users.' ],
'70' => [ 'Revised article',
    'Item design revised.' ],
'71' => [ 'Refurbished article',
    'The characteristic of an item or commodity that has been restored.' ],
'72' => [ 'Vintage',
    'The harvest year of the grapes that are part of the composition of a particular wine.' ],
'73' => [ 'Beverage age',
    'The period during which, after distillation and before bottling, distilled spirits have been stored in containers.' ],
'74' => [ 'Beverage brand',
    'A grouping of beverage products similar in name only, but of different size, age, proof, quality and flavour.' ],
'75' => [ 'Artist',
    'The performing artist(es) of a recorded song or piece of music.' ],
'76' => [ 'Author',
    'The author of a written work.' ],
'77' => [ 'Binding',
    'A description of the type of binding used for a written work.' ],
'78' => [ 'Edition',
    'Description of the edition of a written work.' ],
'79' => [ 'Other physical description',
    'Any other relevant physical description.' ],
'80' => [ 'Publisher',
    'The publisher of a written piece of work as part of the item description.' ],
'81' => [ 'Title',
    'The title of a work.' ],
'82' => [ 'Series title',
    'Title of a series of works.' ],
'83' => [ 'Volume title',
    'The title of a volume of work.' ],
'84' => [ 'Composer',
    'The composer of a recorded song or piece of music.' ],
'85' => [ 'Recording medium',
    'The medium on which a musical recording is made.' ],
'86' => [ 'Music style',
    'The style of music.' ],
'87' => [ 'Promotional event',
    'Describes the promotional event associated with a product.' ],
'88' => [ 'Promotional offer',
    'Describes the additions to the basic product for a promotional event.' ],
'89' => [ 'Alcohol beverage class',
    'Class characteristics for different compositions of alcoholic beverages.' ],
'90' => [ 'Alcohol beverage type',
    'A descriptive term that further defines the class of an alcoholic beverage.' ],
'91' => [ 'Secondary grape',
    'The grape that comprises the second largest percentage of the ingredients used in wine product.' ],
'92' => [ 'Primary grape',
    'The type of grape that comprises the largest percentage of grape in the wine product.' ],
'93' => [ 'Beverage category',
    'A description to designate the beverage category.' ],
'94' => [ 'Beverage flavour',
    'Distinctions from the base product that results in a different taste.' ],
'95' => [ 'Wine growing region',
    'The area where the grape used to produce a wine was harvested.' ],
'96' => [ 'Wine fruit',
    'The fruit that is used as a base to produce a wine.' ],
'97' => [ 'Beverage container characteristics',
    'A description of various beverage container characteristics.' ],
'98' => [ 'Size',
    'Description of size in non-numeric terms.' ],
'99' => [ 'Cell line history',
    'The history of a particular cell line.' ],
'100' => [ 'Project subject',
    'To identify the subject of a given project.' ],
'101' => [ 'Test panel type',
    'Specifies the type of test panel used for the item.' ],
'102' => [ 'Anatomical origin of sample',
    'Anatomical origin of sample.' ],
'103' => [ 'Type of sample',
    'Type of sample such as blood or urine.' ],
'104' => [ 'Shelf-life code',
    'A code indicating the shelf-life of a product.' ],
'105' => [ 'Limiting operation',
    'Code indicating that the item has a limiting operation.' ],
'106' => [ 'Temper',
    'To bring to a required degree of hardness and elasticity by heating and then cooling.' ],
'107' => [ 'Filament',
    'A fine wire heated electrically to incandescence.' ],
'108' => [ 'Denier',
    'The unit of fineness for yarns.' ],
'109' => [ 'Fibre',
    'A threadlike or filament forming part of a product.' ],
'110' => [ 'Lustre',
    'A reflected light or sheen.' ],
'111' => [ 'Shade',
    'The degree to which a colour is mixed with black or is decreasingly illuminated.' ],
'112' => [ 'Tint',
    'A gradation of colour made by adding white to lessen the saturation.' ],
'113' => [ 'Fibre tow',
    'The fibre of flax, hemp or jute prepared for low-grade spinning.' ],
'114' => [ 'Alloy',
    'A homogeneous mixture or solid solution usually of two or more metals.' ],
'115' => [ 'Machine run',
    'Description of the machine run characteristics for a product.' ],
'116' => [ 'Corrosion resistance',
    'The characteristics describing the resistance to chemical deterioration.' ],
'117' => [ 'Visual',
    'Capable of being seen by the eye or with the aid of optics.' ],
'118' => [ 'Electrical',
    "Code indicating the product's electrical characteristics." ],
'119' => [ 'Functional performance',
    "Code indicating the product's functional performance characteristics." ],
'120' => [ 'Chemistry',
    "Code indicating the product's chemical characteristics." ],
'121' => [ 'Physical',
    "Code indicating the product's physical characteristics." ],
'122' => [ 'Magnetic',
    "Code indicating the product's magnetic characteristics." ],
'123' => [ 'Mechanical',
    "Code indicating the product's mechanical characteristics." ],
'124' => [ 'Metallographic',
    "Code indicating the product's metallographic characteristics." ],
'125' => [ 'Dye lot',
    "Code indicating the product's dye lot characteristics." ],
'126' => [ 'Pattern',
    "Code indicating the product's pattern characteristics." ],
'127' => [ 'Appearance',
    'The outward aspect or semblance.' ],
'128' => [ 'Dispersion',
    'The separation of visible light into its colour components by refraction or diffraction.' ],
'129' => [ 'Fluid',
    "Code indicating the product's fluid characteristics." ],
'130' => [ 'Flow',
    'The movement or run in the manner of a liquid.' ],
'131' => [ 'Moisture',
    "Code indicating the product's moisture characteristics." ],
'132' => [ 'Fabric',
    "Code indicating the product's fabric characteristics." ],
'133' => [ 'Shipping unit component',
    'Any designed component of a fixture or container, typically detachable from the base unit for empty return or for cleaning, which provides rigidity, stability, or security when loaded and are an integral part of the container or shipping device and are essential to its functionality.' ],
'134' => [ 'Manufacturing method',
    "Code indicating the product's manufacturing method characteristics." ],
'135' => [ 'Engine',
    'Code indicating the discrete identification of the engine characteristics.' ],
'136' => [ 'Transmission',
    'Code indicating the discrete identification of the transmission characteristics.' ],
'137' => [ 'Controlled substance',
    'Code indicating the controlled substance characteristics.' ],
'139' => [ 'Collateral',
    "Code indicating the product's accompanying or coinciding characteristics." ],
'140' => [ 'Chassis',
    'Code indicating the discrete identification of the chassis characteristics.' ],
'141' => [ 'Compliance method',
    "Code indicating the product's compliance method characteristics." ],
'142' => [ 'Pipe coupling',
    'A collar with internal threads used to join a section of threaded pipe.' ],
'143' => [ 'Drug efficacy',
    "Code indicating the drug's capacity or ability to produce the desired effects." ],
'144' => [ 'Dosage form',
    'Code indicating the physical form of the dosage.' ],
'145' => [ 'Dimensional',
    "Code indicating the product's dimensional characteristics in non-numeric terms." ],
'146' => [ 'Fold configuration',
    "Code indicating the product's fold configuration characteristics." ],
'147' => [ 'Fuel',
    'Code indicating the fuel characteristics.' ],
'148' => [ 'Cell line identifier',
    'Identification of a particular cell line.' ],
'149' => [ 'Hydraulics',
    'The characteristics of a liquid conveyed under pressure through pipes or channels.' ],
'150' => [ 'Coordinates',
    "Code indicating the product's coordinates in non-numeric terms." ],
'151' => [ 'Options',
    'An item available in addition to standard features of a product.' ],
'152' => [ 'Non-prescription drug',
    "Code indicating the non-prescription drug's characteristics." ],
'153' => [ 'Prescription drug',
    "Code indicating the prescription drug's characteristics." ],
'154' => [ 'Source',
    'The derivation of a material thing.' ],
'155' => [ 'Therapeutic class',
    "Code indicating the product's therapeutic class characteristics." ],
'156' => [ 'Therapeutic equivalency',
    "Code indicating the product's therapeutic equivalency characteristics." ],
'157' => [ 'Filter',
    "Code indicating the product's filter characteristics." ],
'158' => [ 'Trim',
    "Code indicating the product's trim characteristics." ],
'159' => [ 'Waste',
    'Code indicating unusable material left over from a process of manufacturing.' ],
'160' => [ 'Bottomhole location method',
    'Code indicating the method for locating the lowest part or surface of a works.' ],
'161' => [ 'Bottomhole pressure method',
    'Code indicating the method for measuring pressures at the lowest part or surface of a works.' ],
'162' => [ 'Common chemical name',
    "Code indicating the product's common chemical name." ],
'163' => [ 'Chemical family name',
    "Code indicating the product's chemical family name." ],
'164' => [ 'Casing or liner type',
    'Code indicating the protective or covering part of a natural or manufactured object.' ],
'165' => [ 'Well direction',
    'Code indicating the well drilling direction.' ],
'166' => [ 'Electronic field',
    "Code indicating the product's electronic field characteristics." ],
'167' => [ 'Formula',
    'Code indicating the formula characteristics in non- numeric terms.' ],
'168' => [ 'Ingredient',
    'A component part of a mixture.' ],
'169' => [ 'Market segment',
    'Code indicating the market segment associated with a product.' ],
'170' => [ 'Odour',
    'The property of a substance that is perceptible by the sense of smell.' ],
'171' => [ 'Physical form',
    'Code indicating the physical form of a product.' ],
'172' => [ 'Well perforation continuity',
    'Code indicating the well perforation continuity characteristics.' ],
'173' => [ 'Well perforation interval',
    'Code indicating the well perforation interval characteristics.' ],
'174' => [ 'Pipeline stream',
    "Code indicating the product's pipeline stream characteristics." ],
'175' => [ 'Surface location method',
    "Code indicating the product's surface location method characteristics." ],
'176' => [ 'Threshold',
    "Code indicating the product's threshold characteristics." ],
'177' => [ 'Well classification',
    'Code indicating the well classification characteristics.' ],
'178' => [ 'Well test type',
    'Code indicating the well test type characteristics.' ],
'179' => [ 'Major grade',
    'Specification of the major grade of the item.' ],
'180' => [ 'Specification',
    'Description of the specification of the item.' ],
'181' => [ 'Test sample location - ends',
    'Code indicating the test sample location on the ends of a product.' ],
'182' => [ 'Product life cycle',
    'Code indicating the period of time between product creation and obsolescence.' ],
'183' => [ 'Storage and display',
    "Code indicating the product's storage or display characteristics." ],
'184' => [ 'Density',
    'A code indicating the relation of weight to volume using non-discrete values.' ],
'185' => [ 'Print orientation',
    'The orientation of the back printing on a form to the front printing on the same form.' ],
'186' => [ 'Solubility',
    'A code indicating the amount of a substance that can be dissolved using a non-discrete value.' ],
'187' => [ 'Material resource',
    'A code to identify the characteristics of a material resource.' ],
'188' => [ 'Other direct resource',
    'A code to identify other direct resources that are charged to a task.' ],
'189' => [ 'Subcontract resource',
    'A code to identify resources that are part of a subcontract.' ],
'190' => [ 'Consumable resource',
    'A code to identify resources that are consumed.' ],
'191' => [ 'Recurring resource',
    'A code to identify a recurring resource.' ],
'192' => [ 'Non recurring resource',
    'A code to identify a resource that is non recurring.' ],
'193' => [ 'Presentation effect',
    'To indicate a presentation effect.' ],
'194' => [ 'Font',
    'This value identifies a font by name.' ],
'195' => [ 'Key-word',
    'A word which may be used as a search key.' ],
'196' => [ 'Additional sectorial characteristics',
    'A code issued on a sectorial basis which identifies any additional characteristics of a product.' ],
'197' => [ 'Product data base management description',
    'A description indicating how a product should be managed in a data base.' ],
'198' => [ 'Cell culture media',
    'The media in which a cell is being grown (cultured).' ],
'199' => [ 'Animal hybridoma',
    'Hybridoma or cells that have been engineered to produce a desired antibody.' ],
'200' => [ 'Virus coexistence, serological',
    'Description of the coexistence of viruses found in blood.' ],
'201' => [ 'Composition',
    'A blend or combination of components that constitute a particular commodity.' ],
'202' => [ 'Vehicle body type',
    'The body type of a vehicle, e.g. four door, two door, convertible.' ],
'203' => [ 'Condition',
    'The condition of the item.' ],
'204' => [ 'Convention on International Trade and Endangered Species',
    '(CITES) indicator An indication that the item is under the Convention on International Trade and Endangered Species (CITES).' ],
'205' => [ 'DDTC military equipment indicator',
    'An indicator that the item is subject to the US State Department Directorate of Defense Trade Controls (DDTC).' ],
'206' => [ 'Driver side',
    'Information on the driver side of the vehicle.' ],
'207' => [ 'Engine power rating, administrative',
    'The administrative engine power unit rating.' ],
'208' => [ 'Enzyme source',
    'The source of an enzyme.' ],
'209' => [ 'Gender',
    'The gender of an item.' ],
'210' => [ 'Geographic isolate',
    'A geographically isolated area.' ],
'211' => [ 'Intergeneric genetically modified',
    'Information that the article has been intergeneric genetically modified.' ],
'212' => [ 'Life stage',
    'Information on the stage of life.' ],
'213' => [ 'Pathovar',
    'Information on the pathovar, the bacterial strain(s) with the same or similar characteristics as the item.' ],
'214' => [ 'Preliminary assessment information rule',
    'Reference to previously provided information from the manufacturer to identify, assess, and manage human health and environmental risks from chemical substances, mixtures, or categories.' ],
'215' => [ 'Protected species',
    'The item is recognized as a protected species by a legislative or regulatory authority.' ],
'216' => [ 'Race',
    'Information on the race of the item.' ],
'217' => [ 'Recombinant genetic insert',
    'Indication of the insertion of one or more nucleotide base pairs into a genetic sequence.' ],
'218' => [ 'Strain (microbiology)',
    'Information on the strain, the genetic variant or subtype of a microorganism of the item.' ],
'219' => [ 'Style',
    'A kind, sort, or type that distinguishes one commodity from another commodity with similar characteristics.' ],
'220' => [ 'Seller assigned commodity name',
    'A name or a term assigned by seller that identifies a commodity.' ],
'221' => [ 'Model name',
    'A model name used to identify the item.' ],
'222' => [ 'Variety',
    'The variety of the item.' ],
'223' => [ 'Brand name',
    'The brand name of an item.' ],
'224' => [ 'Item name, approved',
    'Approved name of the item.' ],
'225' => [ 'Item descriptive name, approved',
    'The approved descriptive name of the item.' ],
'226' => [ 'Common name',
    'The common name of the item.' ],
'227' => [ 'Not for resale to consumer',
    'Item is not for resale to consumer.' ],
'ZZZ' => [ 'Mutually defined',
    'The item characteristic is mutually agreed by the interchanging parties.' ],
);
sub get_codes { return \%code_hash; }

1;
