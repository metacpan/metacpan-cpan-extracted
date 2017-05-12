$XMI::classes = {
                  'DesignElementGroup' => {
                                            'subclasses' => [
                                                              'ReporterGroup',
                                                              'FeatureGroup',
                                                              'CompositeGroup'
                                                            ],
                                            'parent' => 'Identifiable',
                                            'documentation' => 'The DesignElementGroup holds information on either features, reporters, or compositeSequences, particularly that information that is common between all of the DesignElements contained.',
                                            'attrs' => [],
                                            'associations' => [
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '0..1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'species',
                                                                               'documentation' => 'The organism from which the biosequences of this group are from.',
                                                                               'class_id' => 'S.185',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 2',
                                                                                                 'rank' => '2'
                                                                                               },
                                                                               'class_name' => 'OntologyEntry'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'The organism from which the biosequences of this group are from.',
                                                                              'class_id' => 'S.37',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'DesignElementGroup'
                                                                            }
                                                                },
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'types',
                                                                               'documentation' => 'The specific type of a feature, reporter, or composite.  A composite type might be a gene while a reporter type might be a cDNA clone or an oligo.',
                                                                               'class_id' => 'S.185',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 1',
                                                                                                 'rank' => '1'
                                                                                               },
                                                                               'class_name' => 'OntologyEntry'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'The specific type of a feature, reporter, or composite.  A composite type might be a gene while a reporter type might be a cDNA clone or an oligo.',
                                                                              'class_id' => 'S.37',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'DesignElementGroup'
                                                                            }
                                                                }
                                                              ],
                                            'abstract' => 'true',
                                            'methods' => [],
                                            'id' => 'S.37',
                                            'package' => 'ArrayDesign',
                                            'name' => 'DesignElementGroup'
                                          },
                  'ReporterCompositeMap' => {
                                              'parent' => 'DesignElementMap',
                                              'documentation' => 'A ReporterCompositeMap is the description of how source Reporters are transformed into a target CompositeSequences.  For instance, several reporters that tile across a section of a chromosome could be mapped to a CompositeSequence.',
                                              'attrs' => [],
                                              'associations' => [
                                                                  {
                                                                    'other' => {
                                                                                 'cardinality' => '1..N',
                                                                                 'ordering' => 'unordered',
                                                                                 'name' => 'reporterPositionSources',
                                                                                 'documentation' => 'Association to the reporters that compose this CompositeSequence and where those reporters occur.',
                                                                                 'class_id' => 'S.259',
                                                                                 'aggregation' => 'none',
                                                                                 'navigable' => 'true',
                                                                                 'constraint' => {
                                                                                                   'ordered' => 0,
                                                                                                   'constraint' => 'rank: 2',
                                                                                                   'rank' => '2'
                                                                                                 },
                                                                                 'class_name' => 'ReporterPosition'
                                                                               },
                                                                    'self' => {
                                                                                'cardinality' => '1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => undef,
                                                                                'documentation' => 'Association to the reporters that compose this CompositeSequence and where those reporters occur.',
                                                                                'class_id' => 'S.270',
                                                                                'aggregation' => 'composite',
                                                                                'navigable' => 'false',
                                                                                'constraint' => undef,
                                                                                'class_name' => 'ReporterCompositeMap'
                                                                              }
                                                                  },
                                                                  {
                                                                    'other' => {
                                                                                 'cardinality' => '1',
                                                                                 'ordering' => 'unordered',
                                                                                 'name' => 'compositeSequence',
                                                                                 'documentation' => 'A map to the reporters that compose this CompositeSequence.',
                                                                                 'class_id' => 'S.261',
                                                                                 'aggregation' => 'none',
                                                                                 'navigable' => 'true',
                                                                                 'constraint' => {
                                                                                                   'ordered' => 0,
                                                                                                   'constraint' => 'rank: 1',
                                                                                                   'rank' => '1'
                                                                                                 },
                                                                                 'class_name' => 'CompositeSequence'
                                                                               },
                                                                    'self' => {
                                                                                'cardinality' => '0..N',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'reporterCompositeMaps',
                                                                                'documentation' => 'A map to the reporters that compose this CompositeSequence.',
                                                                                'class_id' => 'S.270',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 2',
                                                                                                  'rank' => '2'
                                                                                                },
                                                                                'class_name' => 'ReporterCompositeMap'
                                                                              }
                                                                  }
                                                                ],
                                              'abstract' => 'false',
                                              'methods' => [],
                                              'id' => 'S.270',
                                              'package' => 'DesignElement',
                                              'name' => 'ReporterCompositeMap'
                                            },
                  'SequencePosition' => {
                                          'subclasses' => [
                                                            'ReporterPosition',
                                                            'CompositePosition'
                                                          ],
                                          'parent' => 'Extendable',
                                          'documentation' => 'Designates the position of the Feature in its BioSequence.',
                                          'attrs' => [
                                                       {
                                                         'documentation' => 'The location of the base, for nucleotides, that the SeqFeature starts. ',
                                                         'id' => 'S.237',
                                                         'type' => 'int',
                                                         'name' => 'start'
                                                       },
                                                       {
                                                         'documentation' => 'The location of the base, for nucleotides, that the SeqFeature ends.',
                                                         'id' => 'S.238',
                                                         'type' => 'int',
                                                         'name' => 'end'
                                                       }
                                                     ],
                                          'associations' => [],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.236',
                                          'package' => 'BioSequence',
                                          'name' => 'SequencePosition'
                                        },
                  'ArrayDesign' => {
                                     'subclasses' => [
                                                       'PhysicalArrayDesign'
                                                     ],
                                     'parent' => 'Identifiable',
                                     'documentation' => 'Describes the design of an gene expression layout.  In some cases this might be virtual and, for instance, represent the output from analysis software at the composite level without reporters or features.',
                                     'attrs' => [
                                                  {
                                                    'documentation' => 'The version of this design.',
                                                    'id' => 'S.12',
                                                    'type' => 'String',
                                                    'name' => 'version'
                                                  },
                                                  {
                                                    'documentation' => 'The number of features for this array',
                                                    'id' => 'S.13',
                                                    'type' => 'int',
                                                    'name' => 'numberOfFeatures'
                                                  }
                                                ],
                                     'associations' => [
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'protocolApplications',
                                                                        'documentation' => 'Describes the application of any protocols, such as the methodology used to pick oligos, in the design of the array.',
                                                                        'class_id' => 'S.155',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'ProtocolApplication'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Describes the application of any protocols, such as the methodology used to pick oligos, in the design of the array.',
                                                                       'class_id' => 'S.11',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'ArrayDesign'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'compositeGroups',
                                                                        'documentation' => 'The grouping of like CompositeSequence together.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple CompositeGroups to segregate the technology types.',
                                                                        'class_id' => 'S.38',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 4',
                                                                                          'rank' => '4'
                                                                                        },
                                                                        'class_name' => 'CompositeGroup'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The grouping of like CompositeSequence together.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple CompositeGroups to segregate the technology types.',
                                                                       'class_id' => 'S.11',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'ArrayDesign'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'designProviders',
                                                                        'documentation' => 'The primary contact for information on the array design',
                                                                        'class_id' => 'S.112',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 5',
                                                                                          'rank' => '5'
                                                                                        },
                                                                        'class_name' => 'Contact'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The primary contact for information on the array design',
                                                                       'class_id' => 'S.11',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'ArrayDesign'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'reporterGroups',
                                                                        'documentation' => 'The grouping of like Reporter together.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple ReporterGroups to segregate the technology types.',
                                                                        'class_id' => 'S.32',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 3',
                                                                                          'rank' => '3'
                                                                                        },
                                                                        'class_name' => 'ReporterGroup'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The grouping of like Reporter together.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple ReporterGroups to segregate the technology types.',
                                                                       'class_id' => 'S.11',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'ArrayDesign'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'featureGroups',
                                                                        'documentation' => 'The grouping of like Features together.  Typically for a physical array design, this will be a single grouping of features whose type might be PCR Product or Oligo.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple FeatureGroups to segregate the technology types.',
                                                                        'class_id' => 'S.33',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 2',
                                                                                          'rank' => '2'
                                                                                        },
                                                                        'class_name' => 'FeatureGroup'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The grouping of like Features together.  Typically for a physical array design, this will be a single grouping of features whose type might be PCR Product or Oligo.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple FeatureGroups to segregate the technology types.',
                                                                       'class_id' => 'S.11',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'ArrayDesign'
                                                                     }
                                                         }
                                                       ],
                                     'abstract' => 'false',
                                     'methods' => [],
                                     'id' => 'S.11',
                                     'package' => 'ArrayDesign',
                                     'name' => 'ArrayDesign'
                                   },
                  'Failed' => {
                                'parent' => 'StandardQuantitationType',
                                'documentation' => 'Values associated with this QuantitationType indicate a failure of some kind for a particular DesignElement for a BioAssay.  Of type boolean.',
                                'attrs' => [],
                                'associations' => [],
                                'abstract' => 'false',
                                'methods' => [],
                                'id' => 'S.252',
                                'package' => 'QuantitationType',
                                'name' => 'Failed'
                              },
                  'Unit' => {
                              'subclasses' => [
                                                'TimeUnit',
                                                'DistanceUnit',
                                                'TemperatureUnit',
                                                'QuantityUnit',
                                                'MassUnit',
                                                'VolumeUnit',
                                                'ConcentrationUnit'
                                              ],
                              'parent' => 'Extendable',
                              'documentation' => 'The unit is a strict enumeration of types.',
                              'attrs' => [
                                           {
                                             'documentation' => 'The name of the unit.',
                                             'id' => 'S.196',
                                             'type' => 'String',
                                             'name' => 'unitName'
                                           }
                                         ],
                              'associations' => [],
                              'abstract' => 'true',
                              'methods' => [],
                              'id' => 'S.195',
                              'package' => 'Measurement',
                              'name' => 'Unit'
                            },
                  'ZoneGroup' => {
                                   'parent' => 'Extendable',
                                   'documentation' => 'Specifies a repeating area on an array.  This is useful for printing when the same pattern is repeated in a regular fashion.',
                                   'attrs' => [
                                                {
                                                  'documentation' => 'Spacing between zones, if applicable.',
                                                  'id' => 'S.21',
                                                  'type' => 'float',
                                                  'name' => 'spacingsBetweenZonesX'
                                                },
                                                {
                                                  'documentation' => 'Spacing between zones, if applicable.',
                                                  'id' => 'S.22',
                                                  'type' => 'float',
                                                  'name' => 'spacingsBetweenZonesY'
                                                },
                                                {
                                                  'documentation' => 'The number of zones on the x-axis.',
                                                  'id' => 'S.23',
                                                  'type' => 'int',
                                                  'name' => 'zonesPerX'
                                                },
                                                {
                                                  'documentation' => 'The number of zones on the y-axis.',
                                                  'id' => 'S.24',
                                                  'type' => 'int',
                                                  'name' => 'zonesPerY'
                                                }
                                              ],
                                   'associations' => [
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'zoneLayout',
                                                                      'documentation' => 'Describes the rectangular layout of features in the array design. ',
                                                                      'class_id' => 'S.15',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 2',
                                                                                        'rank' => '2'
                                                                                      },
                                                                      'class_name' => 'ZoneLayout'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'Describes the rectangular layout of features in the array design. ',
                                                                     'class_id' => 'S.20',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'ZoneGroup'
                                                                   }
                                                       },
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'zoneLocations',
                                                                      'documentation' => 'Describes the location of different zones within the array design.',
                                                                      'class_id' => 'S.25',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 3',
                                                                                        'rank' => '3'
                                                                                      },
                                                                      'class_name' => 'Zone'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'Describes the location of different zones within the array design.',
                                                                     'class_id' => 'S.20',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'ZoneGroup'
                                                                   }
                                                       },
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'distanceUnit',
                                                                      'documentation' => 'Unit for the ZoneGroup attributes.',
                                                                      'class_id' => 'S.199',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 1',
                                                                                        'rank' => '1'
                                                                                      },
                                                                      'class_name' => 'DistanceUnit'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'Unit for the ZoneGroup attributes.',
                                                                     'class_id' => 'S.20',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'ZoneGroup'
                                                                   }
                                                       }
                                                     ],
                                   'abstract' => 'false',
                                   'methods' => [],
                                   'id' => 'S.20',
                                   'package' => 'ArrayDesign',
                                   'name' => 'ZoneGroup'
                                 },
                  'Database' => {
                                  'parent' => 'Identifiable',
                                  'documentation' => 'An address to a repository.',
                                  'attrs' => [
                                               {
                                                 'documentation' => 'The version for which a DatabaseReference applies.',
                                                 'id' => 'S.178',
                                                 'type' => 'String',
                                                 'name' => 'version'
                                               },
                                               {
                                                 'documentation' => 'The location of the Database.',
                                                 'id' => 'S.179',
                                                 'type' => 'String',
                                                 'name' => 'URI'
                                               }
                                             ],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'contacts',
                                                                     'documentation' => 'Information on the contacts for the database',
                                                                     'class_id' => 'S.112',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'Contact'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Information on the contacts for the database',
                                                                    'class_id' => 'S.177',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Database'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.177',
                                  'package' => 'Description',
                                  'name' => 'Database'
                                },
                  'QuantitationTypeMap' => {
                                             'parent' => 'Map',
                                             'documentation' => 'A QuantitationTypeMap is the description of how source QuantitationTypes are mathematically transformed into a target QuantitationType.',
                                             'attrs' => [],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'targetQuantitationType',
                                                                                'documentation' => 'The QuantitationType whose value will be produced from the values of the source QuantitationType according to the Protocol.',
                                                                                'class_id' => 'S.241',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'QuantitationType'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'quantitationTypeMaps',
                                                                               'documentation' => 'The QuantitationType whose value will be produced from the values of the source QuantitationType according to the Protocol.',
                                                                               'class_id' => 'S.136',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 5',
                                                                                                 'rank' => '5'
                                                                                               },
                                                                               'class_name' => 'QuantitationTypeMap'
                                                                             }
                                                                 },
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..N',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'sourcesQuantitationType',
                                                                                'documentation' => 'The QuantitationType sources for values for the transformation.',
                                                                                'class_id' => 'S.241',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 2',
                                                                                                  'rank' => '2'
                                                                                                },
                                                                                'class_name' => 'QuantitationType'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The QuantitationType sources for values for the transformation.',
                                                                               'class_id' => 'S.136',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'QuantitationTypeMap'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.136',
                                             'package' => 'BioAssayData',
                                             'name' => 'QuantitationTypeMap'
                                           },
                  'PValue' => {
                                'parent' => 'ConfidenceIndicator',
                                'documentation' => 'Measurement of the accuracy of a quantitation.  Of type float.',
                                'attrs' => [],
                                'associations' => [],
                                'abstract' => 'false',
                                'methods' => [],
                                'id' => 'S.247',
                                'package' => 'QuantitationType',
                                'name' => 'PValue'
                              },
                  'Reporter' => {
                                  'parent' => 'DesignElement',
                                  'documentation' => 'A Design Element that represents some biological material (clone, oligo, etc.) on an array which will report on some biosequence or biosequences.  The derived data from the measured data of its Features represents the presence or absence of the biosequence or biosequences it is reporting on in the BioAssay.

Reporters are Identifiable and several Features on the same array can be mapped to the same reporter as can Features from a different ArrayDesign.  The granularity of the Reporters independence is dependent on the technology and the intent of the ArrayDesign.  Oligos using mature technologies can in general be assumed to be safely replicated on many features where as with PCR Products there might be the desire for quality assurence to make reporters one to one with features and use the mappings to CompositeSequences for replication purposes.',
                                  'attrs' => [],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'failTypes',
                                                                     'documentation' => 'If at some time the reporter is determined to be failed this indicts the failure (doesn\'t report on what it was intended to report on, etc.)',
                                                                     'class_id' => 'S.185',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 3',
                                                                                       'rank' => '3'
                                                                                     },
                                                                     'class_name' => 'OntologyEntry'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'If at some time the reporter is determined to be failed this indicts the failure (doesn\'t report on what it was intended to report on, etc.)',
                                                                    'class_id' => 'S.258',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Reporter'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'warningType',
                                                                     'documentation' => 'Similar to failType but indicates a warning rather than a failure.',
                                                                     'class_id' => 'S.185',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 2',
                                                                                       'rank' => '2'
                                                                                     },
                                                                     'class_name' => 'OntologyEntry'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Similar to failType but indicates a warning rather than a failure.',
                                                                    'class_id' => 'S.258',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Reporter'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'immobilizedCharacteristics',
                                                                     'documentation' => 'The sequence annotation on the BioMaterial this reporter represents.  Typically the sequences will be an Oligo Sequence, Clone or PCR Primer.',
                                                                     'class_id' => 'S.231',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'BioSequence'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The sequence annotation on the BioMaterial this reporter represents.  Typically the sequences will be an Oligo Sequence, Clone or PCR Primer.',
                                                                    'class_id' => 'S.258',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Reporter'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'featureReporterMaps',
                                                                     'documentation' => 'Associates features with their reporter.',
                                                                     'class_id' => 'S.269',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 4',
                                                                                       'rank' => '4'
                                                                                     },
                                                                     'class_name' => 'FeatureReporterMap'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'reporter',
                                                                    'documentation' => 'Associates features with their reporter.',
                                                                    'class_id' => 'S.258',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 1',
                                                                                      'rank' => '1'
                                                                                    },
                                                                    'class_name' => 'Reporter'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.258',
                                  'package' => 'DesignElement',
                                  'name' => 'Reporter'
                                },
                  'Contact' => {
                                 'subclasses' => [
                                                   'Person',
                                                   'Organization'
                                                 ],
                                 'parent' => 'Identifiable',
                                 'documentation' => 'A contact is either a person or an organization.',
                                 'attrs' => [
                                              {
                                                'id' => 'S.113',
                                                'type' => 'String',
                                                'name' => 'URI'
                                              },
                                              {
                                                'id' => 'S.114',
                                                'type' => 'String',
                                                'name' => 'address'
                                              },
                                              {
                                                'id' => 'S.115',
                                                'type' => 'String',
                                                'name' => 'phone'
                                              },
                                              {
                                                'id' => 'S.116',
                                                'type' => 'String',
                                                'name' => 'tollFreePhone'
                                              },
                                              {
                                                'id' => 'S.117',
                                                'type' => 'String',
                                                'name' => 'email'
                                              },
                                              {
                                                'id' => 'S.118',
                                                'type' => 'String',
                                                'name' => 'fax'
                                              }
                                            ],
                                 'associations' => [
                                                     {
                                                       'other' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'roles',
                                                                    'documentation' => 'The roles (lab equipment sales, contractor, etc.) the contact fills.',
                                                                    'class_id' => 'S.185',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 1',
                                                                                      'rank' => '1'
                                                                                    },
                                                                    'class_name' => 'OntologyEntry'
                                                                  },
                                                       'self' => {
                                                                   'cardinality' => '1',
                                                                   'ordering' => 'unordered',
                                                                   'name' => undef,
                                                                   'documentation' => 'The roles (lab equipment sales, contractor, etc.) the contact fills.',
                                                                   'class_id' => 'S.112',
                                                                   'aggregation' => 'composite',
                                                                   'navigable' => 'false',
                                                                   'constraint' => undef,
                                                                   'class_name' => 'Contact'
                                                                 }
                                                     }
                                                   ],
                                 'abstract' => 'true',
                                 'methods' => [],
                                 'id' => 'S.112',
                                 'package' => 'AuditAndSecurity',
                                 'name' => 'Contact'
                               },
                  'Person' => {
                                'parent' => 'Contact',
                                'documentation' => 'A person for which the attributes are self describing.',
                                'attrs' => [
                                             {
                                               'id' => 'S.103',
                                               'type' => 'String',
                                               'name' => 'lastName'
                                             },
                                             {
                                               'id' => 'S.104',
                                               'type' => 'String',
                                               'name' => 'firstName'
                                             },
                                             {
                                               'id' => 'S.105',
                                               'type' => 'String',
                                               'name' => 'midInitials'
                                             }
                                           ],
                                'associations' => [
                                                    {
                                                      'other' => {
                                                                   'cardinality' => '0..1',
                                                                   'ordering' => 'unordered',
                                                                   'name' => 'affiliation',
                                                                   'documentation' => 'The organization a person belongs to.',
                                                                   'class_id' => 'S.110',
                                                                   'aggregation' => 'none',
                                                                   'navigable' => 'true',
                                                                   'constraint' => {
                                                                                     'ordered' => 0,
                                                                                     'constraint' => 'rank: 1',
                                                                                     'rank' => '1'
                                                                                   },
                                                                   'class_name' => 'Organization'
                                                                 },
                                                      'self' => {
                                                                  'cardinality' => '0..N',
                                                                  'ordering' => 'unordered',
                                                                  'name' => undef,
                                                                  'documentation' => 'The organization a person belongs to.',
                                                                  'class_id' => 'S.102',
                                                                  'aggregation' => 'none',
                                                                  'navigable' => 'false',
                                                                  'constraint' => undef,
                                                                  'class_name' => 'Person'
                                                                }
                                                    }
                                                  ],
                                'abstract' => 'false',
                                'methods' => [],
                                'id' => 'S.102',
                                'package' => 'AuditAndSecurity',
                                'name' => 'Person'
                              },
                  'DerivedBioAssay' => {
                                         'parent' => 'BioAssay',
                                         'documentation' => 'A BioAssay that is created by the Transformation BioEvent from one or more MeasuredBioAssays or DerivedBioAssays.',
                                         'attrs' => [],
                                         'associations' => [
                                                             {
                                                               'other' => {
                                                                            'cardinality' => '0..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'derivedBioAssayData',
                                                                            'documentation' => 'The data associated with the DerivedBioAssay.',
                                                                            'class_id' => 'S.126',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 2',
                                                                                              'rank' => '2'
                                                                                            },
                                                                            'class_name' => 'DerivedBioAssayData'
                                                                          },
                                                               'self' => {
                                                                           'cardinality' => '1..N',
                                                                           'ordering' => 'unordered',
                                                                           'name' => undef,
                                                                           'documentation' => 'The data associated with the DerivedBioAssay.',
                                                                           'class_id' => 'S.90',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'false',
                                                                           'constraint' => undef,
                                                                           'class_name' => 'DerivedBioAssay'
                                                                         }
                                                             },
                                                             {
                                                               'other' => {
                                                                            'cardinality' => '0..1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'type',
                                                                            'documentation' => 'The derivation type, for instance collapsed spot replicate, ratio, averaged intensity, bioassay replicates, etc.',
                                                                            'class_id' => 'S.185',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 1',
                                                                                              'rank' => '1'
                                                                                            },
                                                                            'class_name' => 'OntologyEntry'
                                                                          },
                                                               'self' => {
                                                                           'cardinality' => '1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => undef,
                                                                           'documentation' => 'The derivation type, for instance collapsed spot replicate, ratio, averaged intensity, bioassay replicates, etc.',
                                                                           'class_id' => 'S.90',
                                                                           'aggregation' => 'composite',
                                                                           'navigable' => 'false',
                                                                           'constraint' => undef,
                                                                           'class_name' => 'DerivedBioAssay'
                                                                         }
                                                             },
                                                             {
                                                               'other' => {
                                                                            'cardinality' => '0..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'derivedBioAssayMap',
                                                                            'documentation' => 'The DerivedBioAssay that is produced by the sources of the BioAssayMap.',
                                                                            'class_id' => 'S.139',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 3',
                                                                                              'rank' => '3'
                                                                                            },
                                                                            'class_name' => 'BioAssayMap'
                                                                          },
                                                               'self' => {
                                                                           'cardinality' => '1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'bioAssayMapTarget',
                                                                           'documentation' => 'The DerivedBioAssay that is produced by the sources of the BioAssayMap.',
                                                                           'class_id' => 'S.90',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 1',
                                                                                             'rank' => '1'
                                                                                           },
                                                                           'class_name' => 'DerivedBioAssay'
                                                                         }
                                                             }
                                                           ],
                                         'abstract' => 'false',
                                         'methods' => [],
                                         'id' => 'S.90',
                                         'package' => 'BioAssay',
                                         'name' => 'DerivedBioAssay'
                                       },
                  'BioMaterialMeasurement' => {
                                                'parent' => 'Extendable',
                                                'documentation' => 'A BioMaterialMeasurement is a pairing of a source BioMaterial and an amount (Measurement) of that BioMaterial.',
                                                'attrs' => [],
                                                'associations' => [
                                                                    {
                                                                      'other' => {
                                                                                   'cardinality' => '1',
                                                                                   'ordering' => 'unordered',
                                                                                   'name' => 'bioMaterial',
                                                                                   'documentation' => 'A source BioMaterial for a treatment.',
                                                                                   'class_id' => 'S.72',
                                                                                   'aggregation' => 'none',
                                                                                   'navigable' => 'true',
                                                                                   'constraint' => {
                                                                                                     'ordered' => 0,
                                                                                                     'constraint' => 'rank: 1',
                                                                                                     'rank' => '1'
                                                                                                   },
                                                                                   'class_name' => 'BioMaterial'
                                                                                 },
                                                                      'self' => {
                                                                                  'cardinality' => '0..N',
                                                                                  'ordering' => 'unordered',
                                                                                  'name' => undef,
                                                                                  'documentation' => 'A source BioMaterial for a treatment.',
                                                                                  'class_id' => 'S.78',
                                                                                  'aggregation' => 'none',
                                                                                  'navigable' => 'false',
                                                                                  'constraint' => undef,
                                                                                  'class_name' => 'BioMaterialMeasurement'
                                                                                }
                                                                    },
                                                                    {
                                                                      'other' => {
                                                                                   'cardinality' => '0..1',
                                                                                   'ordering' => 'unordered',
                                                                                   'name' => 'measurement',
                                                                                   'documentation' => 'The amount of the BioMaterial.',
                                                                                   'class_id' => 'S.190',
                                                                                   'aggregation' => 'none',
                                                                                   'navigable' => 'true',
                                                                                   'constraint' => {
                                                                                                     'ordered' => 0,
                                                                                                     'constraint' => 'rank: 2',
                                                                                                     'rank' => '2'
                                                                                                   },
                                                                                   'class_name' => 'Measurement'
                                                                                 },
                                                                      'self' => {
                                                                                  'cardinality' => '1',
                                                                                  'ordering' => 'unordered',
                                                                                  'name' => undef,
                                                                                  'documentation' => 'The amount of the BioMaterial.',
                                                                                  'class_id' => 'S.78',
                                                                                  'aggregation' => 'composite',
                                                                                  'navigable' => 'false',
                                                                                  'constraint' => undef,
                                                                                  'class_name' => 'BioMaterialMeasurement'
                                                                                }
                                                                    }
                                                                  ],
                                                'abstract' => 'false',
                                                'methods' => [],
                                                'id' => 'S.78',
                                                'package' => 'BioMaterial',
                                                'name' => 'BioMaterialMeasurement'
                                              },
                  'Map' => {
                             'subclasses' => [
                                               'QuantitationTypeMap',
                                               'DesignElementMap',
                                               'BioAssayMap'
                                             ],
                             'parent' => 'BioEvent',
                             'documentation' => 'A Map is the description of how sources are transformed into a target.  Provides an abstarct base class that separates the mapping BioEvents from the transforming.',
                             'attrs' => [],
                             'associations' => [],
                             'abstract' => 'true',
                             'methods' => [],
                             'id' => 'S.213',
                             'package' => 'BioEvent',
                             'name' => 'Map'
                           },
                  'QuantitationType' => {
                                          'subclasses' => [
                                                            'StandardQuantitationType',
                                                            'SpecializedQuantitationType'
                                                          ],
                                          'parent' => 'Identifiable',
                                          'documentation' => 'A method for calculating a single datum of the matrix (e.g. raw intensity, background, error).
',
                                          'attrs' => [
                                                       {
                                                         'documentation' => 'Indicates whether the quantitation has been measured from the background or from the feature itself.',
                                                         'id' => 'S.242',
                                                         'type' => 'boolean',
                                                         'name' => 'isBackground'
                                                       }
                                                     ],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'channel',
                                                                             'documentation' => 'The optional channel associated with the QuantitationType.',
                                                                             'class_id' => 'S.94',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'Channel'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '0..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The optional channel associated with the QuantitationType.',
                                                                            'class_id' => 'S.241',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'QuantitationType'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'quantitationTypeMaps',
                                                                             'documentation' => 'The QuantitationType whose value will be produced from the values of the source QuantitationType according to the Protocol.',
                                                                             'class_id' => 'S.136',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 5',
                                                                                               'rank' => '5'
                                                                                             },
                                                                             'class_name' => 'QuantitationTypeMap'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'targetQuantitationType',
                                                                            'documentation' => 'The QuantitationType whose value will be produced from the values of the source QuantitationType according to the Protocol.',
                                                                            'class_id' => 'S.241',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 1',
                                                                                              'rank' => '1'
                                                                                            },
                                                                            'class_name' => 'QuantitationType'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'dataType',
                                                                             'documentation' => 'The specific type for the quantitations.  From a controlled vocabulary of {float, int, boolean, etc.}',
                                                                             'class_id' => 'S.185',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 3',
                                                                                               'rank' => '3'
                                                                                             },
                                                                             'class_name' => 'OntologyEntry'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The specific type for the quantitations.  From a controlled vocabulary of {float, int, boolean, etc.}',
                                                                            'class_id' => 'S.241',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'QuantitationType'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'scale',
                                                                             'documentation' => 'Indication of how to interpret the value.  From a suggested vocabulary of {LINEAR | LN | LOG2 |LOG10 | FOLD_CHANGE | OTHER} ',
                                                                             'class_id' => 'S.185',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 2',
                                                                                               'rank' => '2'
                                                                                             },
                                                                             'class_name' => 'OntologyEntry'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'Indication of how to interpret the value.  From a suggested vocabulary of {LINEAR | LN | LOG2 |LOG10 | FOLD_CHANGE | OTHER} ',
                                                                            'class_id' => 'S.241',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'QuantitationType'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'confidenceIndicators',
                                                                             'documentation' => 'The association between a ConfidenceIndicator and the QuantitationType its is an indicator for.',
                                                                             'class_id' => 'S.250',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 4',
                                                                                               'rank' => '4'
                                                                                             },
                                                                             'class_name' => 'ConfidenceIndicator'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'targetQuantitationType',
                                                                            'documentation' => 'The association between a ConfidenceIndicator and the QuantitationType its is an indicator for.',
                                                                            'class_id' => 'S.241',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 1',
                                                                                              'rank' => '1'
                                                                                            },
                                                                            'class_name' => 'QuantitationType'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'true',
                                          'methods' => [],
                                          'id' => 'S.241',
                                          'package' => 'QuantitationType',
                                          'name' => 'QuantitationType'
                                        },
                  'FeatureInformation' => {
                                            'parent' => 'Extendable',
                                            'documentation' => 'As part of the map information, allows the association of one or more differences in the BioMaterial on a feature from the BioMaterial of the Reporter.  Useful for control purposes such as in Affymetrix probe pairs. ',
                                            'attrs' => [],
                                            'associations' => [
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'feature',
                                                                               'documentation' => 'The feature the FeatureInformation is supplying information for.',
                                                                               'class_id' => 'S.262',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 1',
                                                                                                 'rank' => '1'
                                                                                               },
                                                                               'class_name' => 'Feature'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'The feature the FeatureInformation is supplying information for.',
                                                                              'class_id' => 'S.267',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'FeatureInformation'
                                                                            }
                                                                },
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'mismatchInformation',
                                                                               'documentation' => 'Differences in how the feature matches the reporter\'s sequence, typical examples is the Affymetrix probe pair where one of the features is printed with a mismatch to the other feature\'s perfect match.',
                                                                               'class_id' => 'S.263',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 2',
                                                                                                 'rank' => '2'
                                                                                               },
                                                                               'class_name' => 'MismatchInformation'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'Differences in how the feature matches the reporter\'s sequence, typical examples is the Affymetrix probe pair where one of the features is printed with a mismatch to the other feature\'s perfect match.',
                                                                              'class_id' => 'S.267',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'FeatureInformation'
                                                                            }
                                                                }
                                                              ],
                                            'abstract' => 'false',
                                            'methods' => [],
                                            'id' => 'S.267',
                                            'package' => 'DesignElement',
                                            'name' => 'FeatureInformation'
                                          },
                  'Hardware' => {
                                  'parent' => 'Parameterizable',
                                  'documentation' => 'Hardware represents the hardware used.  Examples of Hardware include: computers, scanners, wash stations etc...',
                                  'attrs' => [
                                               {
                                                 'documentation' => 'The model (number) of a piece of hardware.',
                                                 'id' => 'S.159',
                                                 'type' => 'String',
                                                 'name' => 'model'
                                               },
                                               {
                                                 'documentation' => 'The make of the Hardware (its manufacturer).',
                                                 'id' => 'S.160',
                                                 'type' => 'String',
                                                 'name' => 'make'
                                               }
                                             ],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'hardwareManufacturers',
                                                                     'documentation' => 'Contact for information on the Hardware.',
                                                                     'class_id' => 'S.112',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 3',
                                                                                       'rank' => '3'
                                                                                     },
                                                                     'class_name' => 'Contact'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Contact for information on the Hardware.',
                                                                    'class_id' => 'S.158',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Hardware'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'softwares',
                                                                     'documentation' => 'Associates Hardware and Software together.',
                                                                     'class_id' => 'S.157',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 2',
                                                                                       'rank' => '2'
                                                                                     },
                                                                     'class_name' => 'Software'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'hardware',
                                                                    'documentation' => 'Associates Hardware and Software together.',
                                                                    'class_id' => 'S.158',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 2',
                                                                                      'rank' => '2'
                                                                                    },
                                                                    'class_name' => 'Hardware'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'type',
                                                                     'documentation' => 'The type of a piece of Hardware.  Examples include: scanner, wash station...',
                                                                     'class_id' => 'S.185',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'OntologyEntry'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The type of a piece of Hardware.  Examples include: scanner, wash station...',
                                                                    'class_id' => 'S.158',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Hardware'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.158',
                                  'package' => 'Protocol',
                                  'name' => 'Hardware'
                                },
                  'ArrayGroup' => {
                                    'parent' => 'Identifiable',
                                    'documentation' => 'An array package is a physical platform that contains one or more arrays that are separately addressable (e.g. several arrays that can be hybridized on a single microscope slide) or a virtual grouping together of arrays.

The array package that has been manufactured has information about where certain artifacts about the array are located for scanning and feature extraction purposes.',
                                    'attrs' => [
                                                 {
                                                   'documentation' => 'Identifier for the ArrayGroup.',
                                                   'id' => 'S.47',
                                                   'type' => 'String',
                                                   'name' => 'barcode'
                                                 },
                                                 {
                                                   'documentation' => 'If there exist more than one array on a slide or a chip, then the spacing between the arrays is useful so that scanning / feature extraction software can crop images representing 1 unique bioassay. ',
                                                   'id' => 'S.48',
                                                   'type' => 'float',
                                                   'name' => 'arraySpacingX'
                                                 },
                                                 {
                                                   'documentation' => 'If there exist more than one array on a slide or a chip, then the spacing between the arrays is useful so that scanning / feature extraction software can crop images representing 1 unique bioassay. ',
                                                   'id' => 'S.49',
                                                   'type' => 'float',
                                                   'name' => 'arraySpacingY'
                                                 },
                                                 {
                                                   'documentation' => 'This attribute defines the number of arrays on a chip or a slide. ',
                                                   'id' => 'S.50',
                                                   'type' => 'int',
                                                   'name' => 'numArrays'
                                                 },
                                                 {
                                                   'documentation' => 'For a human to determine where the top left side of the array is, such as a barcode or frosted side of the glass, etc.',
                                                   'id' => 'S.51',
                                                   'type' => 'String',
                                                   'name' => 'orientationMark'
                                                 },
                                                 {
                                                   'documentation' => 'One of top, bottom, left or right.',
                                                   'id' => 'S.52',
                                                   'type' => 'enum {top,bottom,left,right}',
                                                   'name' => 'orientationMarkPosition'
                                                 },
                                                 {
                                                   'documentation' => 'The width of the platform',
                                                   'id' => 'S.53',
                                                   'type' => 'float',
                                                   'name' => 'width'
                                                 },
                                                 {
                                                   'documentation' => 'The length of the platform.',
                                                   'id' => 'S.54',
                                                   'type' => 'float',
                                                   'name' => 'length'
                                                 }
                                               ],
                                    'associations' => [
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '1..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'arrays',
                                                                       'documentation' => 'Association between an ArrayGroup and its Arrays, typically the ArrayGroup will represent a slide and the Arrays will be the manufactured so that they may be hybridized separately on that slide. ',
                                                                       'class_id' => 'S.40',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 2',
                                                                                         'rank' => '2'
                                                                                       },
                                                                       'class_name' => 'Array'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'arrayGroup',
                                                                      'documentation' => 'Association between an ArrayGroup and its Arrays, typically the ArrayGroup will represent a slide and the Arrays will be the manufactured so that they may be hybridized separately on that slide. ',
                                                                      'class_id' => 'S.46',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 3',
                                                                                        'rank' => '3'
                                                                                      },
                                                                      'class_name' => 'ArrayGroup'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'fiducials',
                                                                       'documentation' => 'Association to the marks on the Array for alignment for the scanner.',
                                                                       'class_id' => 'S.59',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 1',
                                                                                         'rank' => '1'
                                                                                       },
                                                                       'class_name' => 'Fiducial'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'Association to the marks on the Array for alignment for the scanner.',
                                                                      'class_id' => 'S.46',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'ArrayGroup'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'distanceUnit',
                                                                       'documentation' => 'The unit of the measurement attributes.',
                                                                       'class_id' => 'S.199',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 4',
                                                                                         'rank' => '4'
                                                                                       },
                                                                       'class_name' => 'DistanceUnit'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'The unit of the measurement attributes.',
                                                                      'class_id' => 'S.46',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'ArrayGroup'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'substrateType',
                                                                       'documentation' => 'Commonly, arrays will be spotted on 1x3 glass microscope slides but there is nothing that says this must be the case.  This association is for scanners to inform them on the possible different formats of slides that can contain arrays.',
                                                                       'class_id' => 'S.185',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 3',
                                                                                         'rank' => '3'
                                                                                       },
                                                                       'class_name' => 'OntologyEntry'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'Commonly, arrays will be spotted on 1x3 glass microscope slides but there is nothing that says this must be the case.  This association is for scanners to inform them on the possible different formats of slides that can contain arrays.',
                                                                      'class_id' => 'S.46',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'ArrayGroup'
                                                                    }
                                                        }
                                                      ],
                                    'abstract' => 'false',
                                    'methods' => [],
                                    'id' => 'S.46',
                                    'package' => 'Array',
                                    'name' => 'ArrayGroup'
                                  },
                  'FeatureLocation' => {
                                         'parent' => 'Extendable',
                                         'documentation' => 'Specifies where a feature is located relative to a grid.',
                                         'attrs' => [
                                                      {
                                                        'documentation' => 'row position in the Zone',
                                                        'id' => 'S.272',
                                                        'type' => 'int',
                                                        'name' => 'row'
                                                      },
                                                      {
                                                        'documentation' => 'column position in the Zone.',
                                                        'id' => 'S.273',
                                                        'type' => 'int',
                                                        'name' => 'column'
                                                      }
                                                    ],
                                         'associations' => [],
                                         'abstract' => 'false',
                                         'methods' => [],
                                         'id' => 'S.271',
                                         'package' => 'DesignElement',
                                         'name' => 'FeatureLocation'
                                       },
                  'PhysicalArrayDesign' => {
                                             'parent' => 'ArrayDesign',
                                             'documentation' => 'A design that is expected to be used to manufacture physical arrays.',
                                             'attrs' => [],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..N',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'zoneGroups',
                                                                                'documentation' => 'In the case where the array design is specified by one or more zones, allows specifying where those zones are located.',
                                                                                'class_id' => 'S.20',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 2',
                                                                                                  'rank' => '2'
                                                                                                },
                                                                                'class_name' => 'ZoneGroup'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'In the case where the array design is specified by one or more zones, allows specifying where those zones are located.',
                                                                               'class_id' => 'S.14',
                                                                               'aggregation' => 'composite',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'PhysicalArrayDesign'
                                                                             }
                                                                 },
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'surfaceType',
                                                                                'documentation' => 'The type of surface from a controlled vocabulary that would include terms such as non-absorptive, absorptive, etc.',
                                                                                'class_id' => 'S.185',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'OntologyEntry'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The type of surface from a controlled vocabulary that would include terms such as non-absorptive, absorptive, etc.',
                                                                               'class_id' => 'S.14',
                                                                               'aggregation' => 'composite',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'PhysicalArrayDesign'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.14',
                                             'package' => 'ArrayDesign',
                                             'name' => 'PhysicalArrayDesign'
                                           },
                  'SeqFeatureLocation' => {
                                            'parent' => 'Extendable',
                                            'documentation' => 'The location of the SeqFeature annotation.',
                                            'attrs' => [
                                                         {
                                                           'documentation' => 'Indicates the direction and/or type of the SeqFeature, i.e. whether it is in the 5\' or 3\' direction, is double stranded, etc.',
                                                           'id' => 'S.230',
                                                           'type' => 'String',
                                                           'name' => 'strandType'
                                                         }
                                                       ],
                                            'associations' => [
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'subregions',
                                                                               'documentation' => 'Regions within the SeqFeature.',
                                                                               'class_id' => 'S.229',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 1',
                                                                                                 'rank' => '1'
                                                                                               },
                                                                               'class_name' => 'SeqFeatureLocation'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'Regions within the SeqFeature.',
                                                                              'class_id' => 'S.229',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'SeqFeatureLocation'
                                                                            }
                                                                },
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'coordinate',
                                                                               'documentation' => 'At which base pairs or amino acid this SeqFeature begins and ends.',
                                                                               'class_id' => 'S.236',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 2',
                                                                                                 'rank' => '2'
                                                                                               },
                                                                               'class_name' => 'SequencePosition'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'At which base pairs or amino acid this SeqFeature begins and ends.',
                                                                              'class_id' => 'S.229',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'SeqFeatureLocation'
                                                                            }
                                                                }
                                                              ],
                                            'abstract' => 'false',
                                            'methods' => [],
                                            'id' => 'S.229',
                                            'package' => 'BioSequence',
                                            'name' => 'SeqFeatureLocation'
                                          },
                  'Error' => {
                               'parent' => 'ConfidenceIndicator',
                               'documentation' => 'Error measurement of a quantitation.  Of type float.',
                               'attrs' => [],
                               'associations' => [],
                               'abstract' => 'false',
                               'methods' => [],
                               'id' => 'S.246',
                               'package' => 'QuantitationType',
                               'name' => 'Error'
                             },
                  'Position' => {
                                  'parent' => 'Extendable',
                                  'documentation' => 'Specifies a position on an array.',
                                  'attrs' => [
                                               {
                                                 'documentation' => 'The horizontal distance from the upper left corner of the array.',
                                                 'id' => 'S.256',
                                                 'type' => 'float',
                                                 'name' => 'x'
                                               },
                                               {
                                                 'documentation' => 'The vertical distance from the upper left corner of the array.',
                                                 'id' => 'S.257',
                                                 'type' => 'float',
                                                 'name' => 'y'
                                               }
                                             ],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'distanceUnit',
                                                                     'documentation' => 'The units of the x, y positions.',
                                                                     'class_id' => 'S.199',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'DistanceUnit'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The units of the x, y positions.',
                                                                    'class_id' => 'S.255',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Position'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.255',
                                  'package' => 'DesignElement',
                                  'name' => 'Position'
                                },
                  'Audit' => {
                               'parent' => 'Describable',
                               'documentation' => 'Tracks information on the contact that creates or modifies an object.',
                               'attrs' => [
                                            {
                                              'documentation' => 'The date of a change.',
                                              'id' => 'S.108',
                                              'type' => 'Date',
                                              'name' => 'date'
                                            },
                                            {
                                              'documentation' => 'Indicates whether an action is a creation or a modification.',
                                              'id' => 'S.109',
                                              'type' => 'enum {creation,modification}',
                                              'name' => 'action'
                                            }
                                          ],
                               'associations' => [
                                                   {
                                                     'other' => {
                                                                  'cardinality' => '0..1',
                                                                  'ordering' => 'unordered',
                                                                  'name' => 'performer',
                                                                  'documentation' => 'The contact for creating or changing the instance referred to by the Audit.',
                                                                  'class_id' => 'S.112',
                                                                  'aggregation' => 'none',
                                                                  'navigable' => 'true',
                                                                  'constraint' => {
                                                                                    'ordered' => 0,
                                                                                    'constraint' => 'rank: 1',
                                                                                    'rank' => '1'
                                                                                  },
                                                                  'class_name' => 'Contact'
                                                                },
                                                     'self' => {
                                                                 'cardinality' => '0..N',
                                                                 'ordering' => 'unordered',
                                                                 'name' => undef,
                                                                 'documentation' => 'The contact for creating or changing the instance referred to by the Audit.',
                                                                 'class_id' => 'S.107',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'false',
                                                                 'constraint' => undef,
                                                                 'class_name' => 'Audit'
                                                               }
                                                   }
                                                 ],
                               'abstract' => 'false',
                               'methods' => [],
                               'id' => 'S.107',
                               'package' => 'AuditAndSecurity',
                               'name' => 'Audit'
                             },
                  'Feature' => {
                                 'parent' => 'DesignElement',
                                 'documentation' => 'An intended  position on an array.
',
                                 'attrs' => [],
                                 'associations' => [
                                                     {
                                                       'other' => {
                                                                    'cardinality' => '0..1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'zone',
                                                                    'documentation' => 'A reference to the zone this feature is in.',
                                                                    'class_id' => 'S.25',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 4',
                                                                                      'rank' => '4'
                                                                                    },
                                                                    'class_name' => 'Zone'
                                                                  },
                                                       'self' => {
                                                                   'cardinality' => '0..N',
                                                                   'ordering' => 'unordered',
                                                                   'name' => undef,
                                                                   'documentation' => 'A reference to the zone this feature is in.',
                                                                   'class_id' => 'S.262',
                                                                   'aggregation' => 'none',
                                                                   'navigable' => 'false',
                                                                   'constraint' => undef,
                                                                   'class_name' => 'Feature'
                                                                 }
                                                     },
                                                     {
                                                       'other' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'featureGroup',
                                                                    'documentation' => 'The features that belong to this group.',
                                                                    'class_id' => 'S.33',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 6',
                                                                                      'rank' => '6'
                                                                                    },
                                                                    'class_name' => 'FeatureGroup'
                                                                  },
                                                       'self' => {
                                                                   'cardinality' => '1..N',
                                                                   'ordering' => 'unordered',
                                                                   'name' => 'features',
                                                                   'documentation' => 'The features that belong to this group.',
                                                                   'class_id' => 'S.262',
                                                                   'aggregation' => 'none',
                                                                   'navigable' => 'true',
                                                                   'constraint' => {
                                                                                     'ordered' => 0,
                                                                                     'constraint' => 'rank: 4',
                                                                                     'rank' => '4'
                                                                                   },
                                                                   'class_name' => 'Feature'
                                                                 }
                                                     },
                                                     {
                                                       'other' => {
                                                                    'cardinality' => '0..1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'position',
                                                                    'documentation' => 'The position of the feature on the array, relative to the top, left corner.',
                                                                    'class_id' => 'S.255',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 3',
                                                                                      'rank' => '3'
                                                                                    },
                                                                    'class_name' => 'Position'
                                                                  },
                                                       'self' => {
                                                                   'cardinality' => '1',
                                                                   'ordering' => 'unordered',
                                                                   'name' => undef,
                                                                   'documentation' => 'The position of the feature on the array, relative to the top, left corner.',
                                                                   'class_id' => 'S.262',
                                                                   'aggregation' => 'composite',
                                                                   'navigable' => 'false',
                                                                   'constraint' => undef,
                                                                   'class_name' => 'Feature'
                                                                 }
                                                     },
                                                     {
                                                       'other' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'controlFeatures',
                                                                    'documentation' => 'Associates features with their control features.',
                                                                    'class_id' => 'S.262',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 1',
                                                                                      'rank' => '1'
                                                                                    },
                                                                    'class_name' => 'Feature'
                                                                  },
                                                       'self' => {
                                                                   'cardinality' => '0..N',
                                                                   'ordering' => 'unordered',
                                                                   'name' => 'controlledFeatures',
                                                                   'documentation' => 'Associates features with their control features.',
                                                                   'class_id' => 'S.262',
                                                                   'aggregation' => 'none',
                                                                   'navigable' => 'true',
                                                                   'constraint' => {
                                                                                     'ordered' => 0,
                                                                                     'constraint' => 'rank: 2',
                                                                                     'rank' => '2'
                                                                                   },
                                                                   'class_name' => 'Feature'
                                                                 }
                                                     },
                                                     {
                                                       'other' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'controlledFeatures',
                                                                    'documentation' => 'Associates features with their control features.',
                                                                    'class_id' => 'S.262',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 2',
                                                                                      'rank' => '2'
                                                                                    },
                                                                    'class_name' => 'Feature'
                                                                  },
                                                       'self' => {
                                                                   'cardinality' => '0..N',
                                                                   'ordering' => 'unordered',
                                                                   'name' => 'controlFeatures',
                                                                   'documentation' => 'Associates features with their control features.',
                                                                   'class_id' => 'S.262',
                                                                   'aggregation' => 'none',
                                                                   'navigable' => 'true',
                                                                   'constraint' => {
                                                                                     'ordered' => 0,
                                                                                     'constraint' => 'rank: 1',
                                                                                     'rank' => '1'
                                                                                   },
                                                                   'class_name' => 'Feature'
                                                                 }
                                                     },
                                                     {
                                                       'other' => {
                                                                    'cardinality' => '0..1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'featureLocation',
                                                                    'documentation' => 'Location of this feature relative to a grid.',
                                                                    'class_id' => 'S.271',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 5',
                                                                                      'rank' => '5'
                                                                                    },
                                                                    'class_name' => 'FeatureLocation'
                                                                  },
                                                       'self' => {
                                                                   'cardinality' => '1',
                                                                   'ordering' => 'unordered',
                                                                   'name' => undef,
                                                                   'documentation' => 'Location of this feature relative to a grid.',
                                                                   'class_id' => 'S.262',
                                                                   'aggregation' => 'composite',
                                                                   'navigable' => 'false',
                                                                   'constraint' => undef,
                                                                   'class_name' => 'Feature'
                                                                 }
                                                     }
                                                   ],
                                 'abstract' => 'false',
                                 'methods' => [],
                                 'id' => 'S.262',
                                 'package' => 'DesignElement',
                                 'name' => 'Feature'
                               },
                  'MismatchInformation' => {
                                             'parent' => 'Extendable',
                                             'documentation' => 'Describes how a reporter varies from its ReporterCharacteristics sequence(s) or how a Feature varies from its Reporter sequence.',
                                             'attrs' => [
                                                          {
                                                            'documentation' => 'Offset into the sequence that the mismatch occurs.',
                                                            'id' => 'S.264',
                                                            'type' => 'int',
                                                            'name' => 'startCoord'
                                                          },
                                                          {
                                                            'documentation' => 'The sequence that replaces the specified sequence starting at start_coord.',
                                                            'id' => 'S.265',
                                                            'type' => 'String',
                                                            'name' => 'newSequence'
                                                          },
                                                          {
                                                            'documentation' => 'Length of the original sequence that is replaced.  A deletion is specified when the length of the newSequence is less than the replacedLength.',
                                                            'id' => 'S.266',
                                                            'type' => 'int',
                                                            'name' => 'replacedLength'
                                                          }
                                                        ],
                                             'associations' => [],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.263',
                                             'package' => 'DesignElement',
                                             'name' => 'MismatchInformation'
                                           },
                  'OntologyEntry' => {
                                       'parent' => 'Extendable',
                                       'documentation' => 'A single entry from an ontology or a controlled vocabulary.  For instance, category could be \'species name\', value could be \'homo sapiens\' and ontology would  be taxonomy database, NCBI.',
                                       'attrs' => [
                                                    {
                                                      'documentation' => 'The category to which this entry belongs.',
                                                      'id' => 'S.186',
                                                      'type' => 'String',
                                                      'name' => 'category'
                                                    },
                                                    {
                                                      'documentation' => 'The value for this entry in this category.  ',
                                                      'id' => 'S.187',
                                                      'type' => 'String',
                                                      'name' => 'value'
                                                    },
                                                    {
                                                      'documentation' => 'The description of the meaning for this entry.',
                                                      'id' => 'S.188',
                                                      'type' => 'String',
                                                      'name' => 'description'
                                                    }
                                                  ],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '0..1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'ontologyReference',
                                                                          'documentation' => 'Many ontology entries will not yet have formalized ontologies.  In those cases, they will not have a database reference to the ontology.

In the future it is highly encouraged that these ontologies be developed and ontologyEntry be subclassed from DatabaseReference.',
                                                                          'class_id' => 'S.173',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'DatabaseEntry'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'Many ontology entries will not yet have formalized ontologies.  In those cases, they will not have a database reference to the ontology.

In the future it is highly encouraged that these ontologies be developed and ontologyEntry be subclassed from DatabaseReference.',
                                                                         'class_id' => 'S.185',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'OntologyEntry'
                                                                       }
                                                           },
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '0..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'associations',
                                                                          'documentation' => 'Allows an instance of an OntologyEntry to be further qualified.',
                                                                          'class_id' => 'S.185',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 2',
                                                                                            'rank' => '2'
                                                                                          },
                                                                          'class_name' => 'OntologyEntry'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'Allows an instance of an OntologyEntry to be further qualified.',
                                                                         'class_id' => 'S.185',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'OntologyEntry'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.185',
                                       'package' => 'Description',
                                       'name' => 'OntologyEntry'
                                     },
                  'QuantitationTypeDimension' => {
                                                   'parent' => 'Identifiable',
                                                   'documentation' => 'An ordered list of quantitationTypes.',
                                                   'attrs' => [],
                                                   'associations' => [
                                                                       {
                                                                         'other' => {
                                                                                      'cardinality' => '0..N',
                                                                                      'ordering' => 'unordered',
                                                                                      'name' => 'quantitationTypes',
                                                                                      'documentation' => 'The QuantitationTypes for this Dimension.',
                                                                                      'class_id' => 'S.241',
                                                                                      'aggregation' => 'none',
                                                                                      'navigable' => 'true',
                                                                                      'constraint' => {
                                                                                                        'ordered' => 1,
                                                                                                        'constraint' => 'ordered rank: 1',
                                                                                                        'rank' => '1'
                                                                                                      },
                                                                                      'class_name' => 'QuantitationType'
                                                                                    },
                                                                         'self' => {
                                                                                     'cardinality' => '0..N',
                                                                                     'ordering' => 'unordered',
                                                                                     'name' => undef,
                                                                                     'documentation' => 'The QuantitationTypes for this Dimension.',
                                                                                     'class_id' => 'S.121',
                                                                                     'aggregation' => 'none',
                                                                                     'navigable' => 'false',
                                                                                     'constraint' => undef,
                                                                                     'class_name' => 'QuantitationTypeDimension'
                                                                                   }
                                                                       }
                                                                     ],
                                                   'abstract' => 'false',
                                                   'methods' => [],
                                                   'id' => 'S.121',
                                                   'package' => 'BioAssayData',
                                                   'name' => 'QuantitationTypeDimension'
                                                 },
                  'Description' => {
                                     'parent' => 'Describable',
                                     'documentation' => 'A free text description of an object.',
                                     'attrs' => [
                                                  {
                                                    'documentation' => 'The description.',
                                                    'id' => 'S.171',
                                                    'type' => 'String',
                                                    'name' => 'text'
                                                  },
                                                  {
                                                    'documentation' => 'A reference to the location and type of an outside resource.',
                                                    'id' => 'S.172',
                                                    'type' => 'String',
                                                    'name' => 'URI'
                                                  }
                                                ],
                                     'associations' => [
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'databaseReferences',
                                                                        'documentation' => 'References to entries in databases.',
                                                                        'class_id' => 'S.173',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 3',
                                                                                          'rank' => '3'
                                                                                        },
                                                                        'class_name' => 'DatabaseEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'References to entries in databases.',
                                                                       'class_id' => 'S.170',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'Description'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'bibliographicReferences',
                                                                        'documentation' => 'References to existing literature.',
                                                                        'class_id' => 'S.215',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 4',
                                                                                          'rank' => '4'
                                                                                        },
                                                                        'class_name' => 'BibliographicReference'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'References to existing literature.',
                                                                       'class_id' => 'S.170',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'Description'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'externalReference',
                                                                        'documentation' => 'Specifies where the described instance was originally obtained from.',
                                                                        'class_id' => 'S.180',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'ExternalReference'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Specifies where the described instance was originally obtained from.',
                                                                       'class_id' => 'S.170',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'Description'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'annotations',
                                                                        'documentation' => 'Allows specification of ontology entries related to the instance being described.',
                                                                        'class_id' => 'S.185',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 2',
                                                                                          'rank' => '2'
                                                                                        },
                                                                        'class_name' => 'OntologyEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Allows specification of ontology entries related to the instance being described.',
                                                                       'class_id' => 'S.170',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'Description'
                                                                     }
                                                         }
                                                       ],
                                     'abstract' => 'false',
                                     'methods' => [],
                                     'id' => 'S.170',
                                     'package' => 'Description',
                                     'name' => 'Description'
                                   },
                  'BioDataValues' => {
                                       'subclasses' => [
                                                         'BioDataCube',
                                                         'BioDataTuples'
                                                       ],
                                       'parent' => 'Extendable',
                                       'documentation' => 'The actual values for the BioAssayCube. ',
                                       'attrs' => [],
                                       'associations' => [],
                                       'abstract' => 'true',
                                       'methods' => [],
                                       'id' => 'S.133',
                                       'package' => 'BioAssayData',
                                       'name' => 'BioDataValues'
                                     },
                  'QuantitationTypeMapping' => {
                                                 'parent' => 'Extendable',
                                                 'documentation' => 'Container of the mappings of the input QuantitationType dimensions to the output QuantitationType dimension.',
                                                 'attrs' => [],
                                                 'associations' => [
                                                                     {
                                                                       'other' => {
                                                                                    'cardinality' => '1..N',
                                                                                    'ordering' => 'unordered',
                                                                                    'name' => 'quantitationTypeMaps',
                                                                                    'documentation' => 'The maps for the QuantitationTypes.',
                                                                                    'class_id' => 'S.136',
                                                                                    'aggregation' => 'none',
                                                                                    'navigable' => 'true',
                                                                                    'constraint' => {
                                                                                                      'ordered' => 0,
                                                                                                      'constraint' => 'rank: 1',
                                                                                                      'rank' => '1'
                                                                                                    },
                                                                                    'class_name' => 'QuantitationTypeMap'
                                                                                  },
                                                                       'self' => {
                                                                                   'cardinality' => '0..N',
                                                                                   'ordering' => 'unordered',
                                                                                   'name' => undef,
                                                                                   'documentation' => 'The maps for the QuantitationTypes.',
                                                                                   'class_id' => 'S.128',
                                                                                   'aggregation' => 'none',
                                                                                   'navigable' => 'false',
                                                                                   'constraint' => undef,
                                                                                   'class_name' => 'QuantitationTypeMapping'
                                                                                 }
                                                                     }
                                                                   ],
                                                 'abstract' => 'false',
                                                 'methods' => [],
                                                 'id' => 'S.128',
                                                 'package' => 'BioAssayData',
                                                 'name' => 'QuantitationTypeMapping'
                                               },
                  'NameValueType' => {
                                       'parent' => undef,
                                       'documentation' => 'A tuple designed to store data, keyed by a name and type.',
                                       'attrs' => [
                                                    {
                                                      'documentation' => 'The name of the key.',
                                                      'id' => 'S.7',
                                                      'type' => 'String',
                                                      'name' => 'name'
                                                    },
                                                    {
                                                      'documentation' => 'The value of the name.',
                                                      'id' => 'S.8',
                                                      'type' => 'String',
                                                      'name' => 'value'
                                                    },
                                                    {
                                                      'documentation' => 'The type of the key.',
                                                      'id' => 'S.9',
                                                      'type' => 'String',
                                                      'name' => 'type'
                                                    }
                                                  ],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '0..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'propertySets',
                                                                          'documentation' => 'Allows nested specification of name/value pairs',
                                                                          'class_id' => 'S.6',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'NameValueType'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'Allows nested specification of name/value pairs',
                                                                         'class_id' => 'S.6',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'NameValueType'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.6',
                                       'package' => 'MAGE',
                                       'name' => 'NameValueType'
                                     },
                  'BioAssayDatum' => {
                                       'parent' => 'Extendable',
                                       'documentation' => 'A single cell of the quantitation, bioAssay, designElement matrix.',
                                       'attrs' => [
                                                    {
                                                      'documentation' => 'The datum value.',
                                                      'id' => 'S.125',
                                                      'type' => 'any',
                                                      'name' => 'value'
                                                    }
                                                  ],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'bioAssay',
                                                                          'documentation' => 'The BioAssay associated with the value of the BioAssayDatum.',
                                                                          'class_id' => 'S.93',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'BioAssay'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The BioAssay associated with the value of the BioAssayDatum.',
                                                                         'class_id' => 'S.124',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'BioAssayDatum'
                                                                       }
                                                           },
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'designElement',
                                                                          'documentation' => 'The DesignElement associated with the value of the BioAssayDatum.',
                                                                          'class_id' => 'S.254',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 2',
                                                                                            'rank' => '2'
                                                                                          },
                                                                          'class_name' => 'DesignElement'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The DesignElement associated with the value of the BioAssayDatum.',
                                                                         'class_id' => 'S.124',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'BioAssayDatum'
                                                                       }
                                                           },
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'quantitationType',
                                                                          'documentation' => 'The QuantitationType associated with the value of the BioAssayDatum.',
                                                                          'class_id' => 'S.241',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 3',
                                                                                            'rank' => '3'
                                                                                          },
                                                                          'class_name' => 'QuantitationType'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The QuantitationType associated with the value of the BioAssayDatum.',
                                                                         'class_id' => 'S.124',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'BioAssayDatum'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.124',
                                       'package' => 'BioAssayData',
                                       'name' => 'BioAssayDatum'
                                     },
                  'DesignElementDimension' => {
                                                'subclasses' => [
                                                                  'CompositeSequenceDimension',
                                                                  'ReporterDimension',
                                                                  'FeatureDimension'
                                                                ],
                                                'parent' => 'Identifiable',
                                                'documentation' => 'An ordered list of designElements. It will be realized as one of its three subclasses.',
                                                'attrs' => [],
                                                'associations' => [],
                                                'abstract' => 'true',
                                                'methods' => [],
                                                'id' => 'S.123',
                                                'package' => 'BioAssayData',
                                                'name' => 'DesignElementDimension'
                                              },
                  'DesignElement' => {
                                       'subclasses' => [
                                                         'Reporter',
                                                         'CompositeSequence',
                                                         'Feature'
                                                       ],
                                       'parent' => 'Identifiable',
                                       'documentation' => 'An element of an array.  This is generally of type feature but can be specified as reporters or compositeSequence for arrays that are abstracted from a physical array.',
                                       'attrs' => [],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '0..1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'controlType',
                                                                          'documentation' => 'If the design element represents a control, the type of control it is (normalization, deletion, negative, positive, etc.)',
                                                                          'class_id' => 'S.185',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'OntologyEntry'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'If the design element represents a control, the type of control it is (normalization, deletion, negative, positive, etc.)',
                                                                         'class_id' => 'S.254',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'DesignElement'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'true',
                                       'methods' => [],
                                       'id' => 'S.254',
                                       'package' => 'DesignElement',
                                       'name' => 'DesignElement'
                                     },
                  'PresentAbsent' => {
                                       'parent' => 'StandardQuantitationType',
                                       'documentation' => 'Indicates relative presence or absence.  From the enumeration AbsoluteCallTypeEnum {Present | Absent | Marginal | No call} or ComparisonCallTypeEnum {Increase I Marginal Increase | Decrease | Marginal Decrease |  No change | No Call | Unknown }, as specified by the dataType.',
                                       'attrs' => [],
                                       'associations' => [],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.251',
                                       'package' => 'QuantitationType',
                                       'name' => 'PresentAbsent'
                                     },
                  'Transformation' => {
                                        'parent' => 'BioEvent',
                                        'documentation' => 'The process by which derivedBioAssays are created from measuredBioAssays and/or derivedBioAssays.  It uses mappings to indicate the input and output dimensions.  ',
                                        'attrs' => [],
                                        'associations' => [
                                                            {
                                                              'other' => {
                                                                           'cardinality' => '0..N',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'bioAssayDataSources',
                                                                           'documentation' => 'The BioAssayData sources that the Transformation event uses to produce the target DerivedBioAssayData.',
                                                                           'class_id' => 'S.120',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 1',
                                                                                             'rank' => '1'
                                                                                           },
                                                                           'class_name' => 'BioAssayData'
                                                                         },
                                                              'self' => {
                                                                          'cardinality' => '0..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => undef,
                                                                          'documentation' => 'The BioAssayData sources that the Transformation event uses to produce the target DerivedBioAssayData.',
                                                                          'class_id' => 'S.137',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'false',
                                                                          'constraint' => undef,
                                                                          'class_name' => 'Transformation'
                                                                        }
                                                            },
                                                            {
                                                              'other' => {
                                                                           'cardinality' => '0..1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'bioAssayMapping',
                                                                           'documentation' => 'The collection of mappings for the BioAssays.',
                                                                           'class_id' => 'S.122',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 5',
                                                                                             'rank' => '5'
                                                                                           },
                                                                           'class_name' => 'BioAssayMapping'
                                                                         },
                                                              'self' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => undef,
                                                                          'documentation' => 'The collection of mappings for the BioAssays.',
                                                                          'class_id' => 'S.137',
                                                                          'aggregation' => 'composite',
                                                                          'navigable' => 'false',
                                                                          'constraint' => undef,
                                                                          'class_name' => 'Transformation'
                                                                        }
                                                            },
                                                            {
                                                              'other' => {
                                                                           'cardinality' => '1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'derivedBioAssayDataTarget',
                                                                           'documentation' => 'The association between the DerivedBioAssayData and the Transformation event that produced it.',
                                                                           'class_id' => 'S.126',
                                                                           'aggregation' => 'composite',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 2',
                                                                                             'rank' => '2'
                                                                                           },
                                                                           'class_name' => 'DerivedBioAssayData'
                                                                         },
                                                              'self' => {
                                                                          'cardinality' => '0..1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'producerTransformation',
                                                                          'documentation' => 'The association between the DerivedBioAssayData and the Transformation event that produced it.',
                                                                          'class_id' => 'S.137',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'Transformation'
                                                                        }
                                                            },
                                                            {
                                                              'other' => {
                                                                           'cardinality' => '0..1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'quantitationTypeMapping',
                                                                           'documentation' => 'The collection of mappings for the QuantitationTypes.',
                                                                           'class_id' => 'S.128',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 3',
                                                                                             'rank' => '3'
                                                                                           },
                                                                           'class_name' => 'QuantitationTypeMapping'
                                                                         },
                                                              'self' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => undef,
                                                                          'documentation' => 'The collection of mappings for the QuantitationTypes.',
                                                                          'class_id' => 'S.137',
                                                                          'aggregation' => 'composite',
                                                                          'navigable' => 'false',
                                                                          'constraint' => undef,
                                                                          'class_name' => 'Transformation'
                                                                        }
                                                            },
                                                            {
                                                              'other' => {
                                                                           'cardinality' => '0..1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'designElementMapping',
                                                                           'documentation' => 'The collection of mappings for the DesignElements.',
                                                                           'class_id' => 'S.129',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 4',
                                                                                             'rank' => '4'
                                                                                           },
                                                                           'class_name' => 'DesignElementMapping'
                                                                         },
                                                              'self' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => undef,
                                                                          'documentation' => 'The collection of mappings for the DesignElements.',
                                                                          'class_id' => 'S.137',
                                                                          'aggregation' => 'composite',
                                                                          'navigable' => 'false',
                                                                          'constraint' => undef,
                                                                          'class_name' => 'Transformation'
                                                                        }
                                                            }
                                                          ],
                                        'abstract' => 'false',
                                        'methods' => [],
                                        'id' => 'S.137',
                                        'package' => 'BioAssayData',
                                        'name' => 'Transformation'
                                      },
                  'BioSequence' => {
                                     'parent' => 'Identifiable',
                                     'documentation' => 'A BioSequence is a representation of a DNA, RNA, or protein sequence.  It can be represented by a Clone, Gene, or the sequence.',
                                     'attrs' => [
                                                  {
                                                    'documentation' => 'The number of residues in the biosequence.',
                                                    'id' => 'S.232',
                                                    'type' => 'int',
                                                    'name' => 'length'
                                                  },
                                                  {
                                                    'documentation' => 'If length not positively known will be true',
                                                    'id' => 'S.233',
                                                    'type' => 'boolean',
                                                    'name' => 'isApproximateLength'
                                                  },
                                                  {
                                                    'documentation' => 'Indicates if the BioSequence is circular in nature.',
                                                    'id' => 'S.234',
                                                    'type' => 'boolean',
                                                    'name' => 'isCircular'
                                                  },
                                                  {
                                                    'documentation' => 'The actual components of the sequence, for instance, for DNA a string consisting of A,T,C and G.

The attribute is optional and instead of specified here, can be found through the DatabaseEntry. ',
                                                    'id' => 'S.235',
                                                    'type' => 'String',
                                                    'name' => 'sequence'
                                                  }
                                                ],
                                     'associations' => [
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'sequenceDatabases',
                                                                        'documentation' => 'References an entry in a species database, like GenBank, UniGene, etc.',
                                                                        'class_id' => 'S.173',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'DatabaseEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'References an entry in a species database, like GenBank, UniGene, etc.',
                                                                       'class_id' => 'S.231',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioSequence'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'ontologyEntries',
                                                                        'documentation' => 'Ontology entries referring to common values associated with BioSequences, such as gene names, go ids, etc.',
                                                                        'class_id' => 'S.185',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 2',
                                                                                          'rank' => '2'
                                                                                        },
                                                                        'class_name' => 'OntologyEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Ontology entries referring to common values associated with BioSequences, such as gene names, go ids, etc.',
                                                                       'class_id' => 'S.231',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioSequence'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'polymerType',
                                                                        'documentation' => 'A choice of protein, RNA, or DNA.',
                                                                        'class_id' => 'S.185',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 3',
                                                                                          'rank' => '3'
                                                                                        },
                                                                        'class_name' => 'OntologyEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'A choice of protein, RNA, or DNA.',
                                                                       'class_id' => 'S.231',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioSequence'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'type',
                                                                        'documentation' => 'The type of biosequence, i.e. gene, exon, UniGene cluster, fragment, BAC, EST, etc.',
                                                                        'class_id' => 'S.185',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 4',
                                                                                          'rank' => '4'
                                                                                        },
                                                                        'class_name' => 'OntologyEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The type of biosequence, i.e. gene, exon, UniGene cluster, fragment, BAC, EST, etc.',
                                                                       'class_id' => 'S.231',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioSequence'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'species',
                                                                        'documentation' => 'The organism from which this sequence was obtained.',
                                                                        'class_id' => 'S.185',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 5',
                                                                                          'rank' => '5'
                                                                                        },
                                                                        'class_name' => 'OntologyEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The organism from which this sequence was obtained.',
                                                                       'class_id' => 'S.231',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioSequence'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'seqFeatures',
                                                                        'documentation' => 'Association to annotations for subsequences.  Corresponds to the GenBank Frame Table.',
                                                                        'class_id' => 'S.227',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 6',
                                                                                          'rank' => '6'
                                                                                        },
                                                                        'class_name' => 'SeqFeature'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Association to annotations for subsequences.  Corresponds to the GenBank Frame Table.',
                                                                       'class_id' => 'S.231',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioSequence'
                                                                     }
                                                         }
                                                       ],
                                     'abstract' => 'false',
                                     'methods' => [],
                                     'id' => 'S.231',
                                     'package' => 'BioSequence',
                                     'name' => 'BioSequence'
                                   },
                  'Array' => {
                               'parent' => 'Identifiable',
                               'documentation' => 'The physical substrate along with its features and their annotation',
                               'attrs' => [
                                            {
                                              'documentation' => 'An identifying string, e.g. a barcode.',
                                              'id' => 'S.41',
                                              'type' => 'String',
                                              'name' => 'arrayIdentifier'
                                            },
                                            {
                                              'documentation' => 'This can indicate the x position on a slide, chip, etc. of the first Feature and is usually specified relative to the fiducial.',
                                              'id' => 'S.42',
                                              'type' => 'float',
                                              'name' => 'arrayXOrigin'
                                            },
                                            {
                                              'documentation' => 'This can indicate the y position on a slide, chip, etc. of the first Feature and is usually specified relative to the fiducial.',
                                              'id' => 'S.43',
                                              'type' => 'float',
                                              'name' => 'arrayYOrigin'
                                            },
                                            {
                                              'documentation' => 'What the array origin is relative to, e.g. upper left corner, fiducial, etc.',
                                              'id' => 'S.44',
                                              'type' => 'String',
                                              'name' => 'originRelativeTo'
                                            }
                                          ],
                               'associations' => [
                                                   {
                                                     'other' => {
                                                                  'cardinality' => '1',
                                                                  'ordering' => 'unordered',
                                                                  'name' => 'arrayDesign',
                                                                  'documentation' => 'The association of a physical array with its array design.',
                                                                  'class_id' => 'S.11',
                                                                  'aggregation' => 'none',
                                                                  'navigable' => 'true',
                                                                  'constraint' => {
                                                                                    'ordered' => 0,
                                                                                    'constraint' => 'rank: 1',
                                                                                    'rank' => '1'
                                                                                  },
                                                                  'class_name' => 'ArrayDesign'
                                                                },
                                                     'self' => {
                                                                 'cardinality' => '0..N',
                                                                 'ordering' => 'unordered',
                                                                 'name' => undef,
                                                                 'documentation' => 'The association of a physical array with its array design.',
                                                                 'class_id' => 'S.40',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'false',
                                                                 'constraint' => undef,
                                                                 'class_name' => 'Array'
                                                               }
                                                   },
                                                   {
                                                     'other' => {
                                                                  'cardinality' => '0..1',
                                                                  'ordering' => 'unordered',
                                                                  'name' => 'arrayGroup',
                                                                  'documentation' => 'Association between an ArrayGroup and its Arrays, typically the ArrayGroup will represent a slide and the Arrays will be the manufactured so that they may be hybridized separately on that slide. ',
                                                                  'class_id' => 'S.46',
                                                                  'aggregation' => 'none',
                                                                  'navigable' => 'true',
                                                                  'constraint' => {
                                                                                    'ordered' => 0,
                                                                                    'constraint' => 'rank: 3',
                                                                                    'rank' => '3'
                                                                                  },
                                                                  'class_name' => 'ArrayGroup'
                                                                },
                                                     'self' => {
                                                                 'cardinality' => '1..N',
                                                                 'ordering' => 'unordered',
                                                                 'name' => 'arrays',
                                                                 'documentation' => 'Association between an ArrayGroup and its Arrays, typically the ArrayGroup will represent a slide and the Arrays will be the manufactured so that they may be hybridized separately on that slide. ',
                                                                 'class_id' => 'S.40',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'true',
                                                                 'constraint' => {
                                                                                   'ordered' => 0,
                                                                                   'constraint' => 'rank: 2',
                                                                                   'rank' => '2'
                                                                                 },
                                                                 'class_name' => 'Array'
                                                               }
                                                   },
                                                   {
                                                     'other' => {
                                                                  'cardinality' => '1',
                                                                  'ordering' => 'unordered',
                                                                  'name' => 'information',
                                                                  'documentation' => 'Association between the manufactured array and the information on that manufacture.',
                                                                  'class_id' => 'S.55',
                                                                  'aggregation' => 'none',
                                                                  'navigable' => 'true',
                                                                  'constraint' => {
                                                                                    'ordered' => 0,
                                                                                    'constraint' => 'rank: 2',
                                                                                    'rank' => '2'
                                                                                  },
                                                                  'class_name' => 'ArrayManufacture'
                                                                },
                                                     'self' => {
                                                                 'cardinality' => '1..N',
                                                                 'ordering' => 'unordered',
                                                                 'name' => 'arrays',
                                                                 'documentation' => 'Association between the manufactured array and the information on that manufacture.',
                                                                 'class_id' => 'S.40',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'true',
                                                                 'constraint' => {
                                                                                   'ordered' => 0,
                                                                                   'constraint' => 'rank: 1',
                                                                                   'rank' => '1'
                                                                                 },
                                                                 'class_name' => 'Array'
                                                               }
                                                   },
                                                   {
                                                     'other' => {
                                                                  'cardinality' => '0..N',
                                                                  'ordering' => 'unordered',
                                                                  'name' => 'arrayManufactureDeviations',
                                                                  'documentation' => 'Association to classes to describe deviations from the ArrayDesign.',
                                                                  'class_id' => 'S.58',
                                                                  'aggregation' => 'none',
                                                                  'navigable' => 'true',
                                                                  'constraint' => {
                                                                                    'ordered' => 0,
                                                                                    'constraint' => 'rank: 4',
                                                                                    'rank' => '4'
                                                                                  },
                                                                  'class_name' => 'ArrayManufactureDeviation'
                                                                },
                                                     'self' => {
                                                                 'cardinality' => '1',
                                                                 'ordering' => 'unordered',
                                                                 'name' => undef,
                                                                 'documentation' => 'Association to classes to describe deviations from the ArrayDesign.',
                                                                 'class_id' => 'S.40',
                                                                 'aggregation' => 'composite',
                                                                 'navigable' => 'false',
                                                                 'constraint' => undef,
                                                                 'class_name' => 'Array'
                                                               }
                                                   }
                                                 ],
                               'abstract' => 'false',
                               'methods' => [],
                               'id' => 'S.40',
                               'package' => 'Array',
                               'name' => 'Array'
                             },
                  'PhysicalBioAssay' => {
                                          'parent' => 'BioAssay',
                                          'documentation' => 'A bioAssay created by the bioAssayCreation event (e.g. in gene expression analysis this event is represented by the hybridization event).',
                                          'attrs' => [],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'physicalBioAssayData',
                                                                             'documentation' => 'The Images associated with this PhysicalBioAssay by ImageAcquisition.',
                                                                             'class_id' => 'S.91',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'Image'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The Images associated with this PhysicalBioAssay by ImageAcquisition.',
                                                                            'class_id' => 'S.89',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'PhysicalBioAssay'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'bioAssayCreation',
                                                                             'documentation' => 'The association between the BioAssayCreation event (typically Hybridization) and the PhysicalBioAssay and its annotation of this event.',
                                                                             'class_id' => 'S.96',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 2',
                                                                                               'rank' => '2'
                                                                                             },
                                                                             'class_name' => 'BioAssayCreation'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'physicalBioAssayTarget',
                                                                            'documentation' => 'The association between the BioAssayCreation event (typically Hybridization) and the PhysicalBioAssay and its annotation of this event.',
                                                                            'class_id' => 'S.89',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 3',
                                                                                              'rank' => '3'
                                                                                            },
                                                                            'class_name' => 'PhysicalBioAssay'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'bioAssayTreatments',
                                                                             'documentation' => 'The set of treatments undergone by this PhysicalBioAssay.',
                                                                             'class_id' => 'S.100',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 1,
                                                                                               'constraint' => 'ordered rank: 3',
                                                                                               'rank' => '3'
                                                                                             },
                                                                             'class_name' => 'BioAssayTreatment'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'physicalBioAssay',
                                                                            'documentation' => 'The set of treatments undergone by this PhysicalBioAssay.',
                                                                            'class_id' => 'S.89',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 1',
                                                                                              'rank' => '1'
                                                                                            },
                                                                            'class_name' => 'PhysicalBioAssay'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.89',
                                          'package' => 'BioAssay',
                                          'name' => 'PhysicalBioAssay'
                                        },
                  'BioSource' => {
                                   'parent' => 'BioMaterial',
                                   'documentation' => 'The BioSource is the original source material before any treatment events.  It is also a top node of the directed acyclic graph generated by treatments.   The association to OntologyEntry allows enumeration of a BioSource\'s inherent properties.',
                                   'attrs' => [],
                                   'associations' => [
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'sourceContact',
                                                                      'documentation' => 'The BioSource\'s source is the provider of the biological material (a cell line, strain, etc...).  This could be the ATTC (American Tissue Type Collection).',
                                                                      'class_id' => 'S.112',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 1',
                                                                                        'rank' => '1'
                                                                                      },
                                                                      'class_name' => 'Contact'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The BioSource\'s source is the provider of the biological material (a cell line, strain, etc...).  This could be the ATTC (American Tissue Type Collection).',
                                                                     'class_id' => 'S.71',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'BioSource'
                                                                   }
                                                       }
                                                     ],
                                   'abstract' => 'false',
                                   'methods' => [],
                                   'id' => 'S.71',
                                   'package' => 'BioMaterial',
                                   'name' => 'BioSource'
                                 },
                  'Security' => {
                                  'parent' => 'Identifiable',
                                  'documentation' => 'Permission information for an object as to ownership, write and read permissions.',
                                  'attrs' => [],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'securityGroups',
                                                                     'documentation' => 'Specifies which security groups have permission to view the associated object.',
                                                                     'class_id' => 'S.111',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 2',
                                                                                       'rank' => '2'
                                                                                     },
                                                                     'class_name' => 'SecurityGroup'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Specifies which security groups have permission to view the associated object.',
                                                                    'class_id' => 'S.106',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Security'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'owner',
                                                                     'documentation' => 'The owner of the security rights.',
                                                                     'class_id' => 'S.112',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'Contact'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The owner of the security rights.',
                                                                    'class_id' => 'S.106',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Security'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.106',
                                  'package' => 'AuditAndSecurity',
                                  'name' => 'Security'
                                },
                  'DatabaseEntry' => {
                                       'parent' => 'Extendable',
                                       'documentation' => 'A reference to a record in a database.',
                                       'attrs' => [
                                                    {
                                                      'documentation' => 'The identifier used to look up the record.',
                                                      'id' => 'S.174',
                                                      'type' => 'String',
                                                      'name' => 'accession'
                                                    },
                                                    {
                                                      'documentation' => 'The appropriate version of the accession (if applicable).',
                                                      'id' => 'S.175',
                                                      'type' => 'String',
                                                      'name' => 'accessionVersion'
                                                    },
                                                    {
                                                      'documentation' => 'The location of the record.',
                                                      'id' => 'S.176',
                                                      'type' => 'String',
                                                      'name' => 'URI'
                                                    }
                                                  ],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'database',
                                                                          'documentation' => 'Reference to the database where the DataEntry instance can be found.',
                                                                          'class_id' => 'S.177',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 2',
                                                                                            'rank' => '2'
                                                                                          },
                                                                          'class_name' => 'Database'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'Reference to the database where the DataEntry instance can be found.',
                                                                         'class_id' => 'S.173',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'DatabaseEntry'
                                                                       }
                                                           },
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '0..1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'type',
                                                                          'documentation' => 'The type of record (e.g. a protein in SwissProt, or a yeast strain in SGD).',
                                                                          'class_id' => 'S.185',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'OntologyEntry'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The type of record (e.g. a protein in SwissProt, or a yeast strain in SGD).',
                                                                         'class_id' => 'S.173',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'DatabaseEntry'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.173',
                                       'package' => 'Description',
                                       'name' => 'DatabaseEntry'
                                     },
                  'ExperimentalFactor' => {
                                            'parent' => 'Identifiable',
                                            'documentation' => 'ExperimentFactors are the dependent variables of an experiment (e.g. time, glucose concentration, ...).',
                                            'attrs' => [],
                                            'associations' => [
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'factorValues',
                                                                               'documentation' => 'The pairing of BioAssay FactorValues with the ExperimentDesign ExperimentFactor.',
                                                                               'class_id' => 'S.147',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 2',
                                                                                                 'rank' => '2'
                                                                                               },
                                                                               'class_name' => 'FactorValue'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'experimentalFactor',
                                                                              'documentation' => 'The pairing of BioAssay FactorValues with the ExperimentDesign ExperimentFactor.',
                                                                              'class_id' => 'S.146',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 1',
                                                                                                'rank' => '1'
                                                                                              },
                                                                              'class_name' => 'ExperimentalFactor'
                                                                            }
                                                                },
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '0..1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'category',
                                                                               'documentation' => 'The category of an ExperimentalFactor could be biological (time, [glucose]) or a methodological factor (differing cDNA preparation protocols).',
                                                                               'class_id' => 'S.185',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 1',
                                                                                                 'rank' => '1'
                                                                                               },
                                                                               'class_name' => 'OntologyEntry'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'The category of an ExperimentalFactor could be biological (time, [glucose]) or a methodological factor (differing cDNA preparation protocols).',
                                                                              'class_id' => 'S.146',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'ExperimentalFactor'
                                                                            }
                                                                },
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'annotations',
                                                                               'documentation' => 'Allows describing additional information such as concentration of Tamoxafin with a CASRegistry #.',
                                                                               'class_id' => 'S.185',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 3',
                                                                                                 'rank' => '3'
                                                                                               },
                                                                               'class_name' => 'OntologyEntry'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'Allows describing additional information such as concentration of Tamoxafin with a CASRegistry #.',
                                                                              'class_id' => 'S.146',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'ExperimentalFactor'
                                                                            }
                                                                }
                                                              ],
                                            'abstract' => 'false',
                                            'methods' => [],
                                            'id' => 'S.146',
                                            'package' => 'Experiment',
                                            'name' => 'ExperimentalFactor'
                                          },
                  'Extendable' => {
                                    'subclasses' => [
                                                      'NodeValue',
                                                      'DatabaseEntry',
                                                      'ZoneLayout',
                                                      'ZoneGroup',
                                                      'ExternalReference',
                                                      'Position',
                                                      'OntologyEntry',
                                                      'MismatchInformation',
                                                      'Measurement',
                                                      'FeatureInformation',
                                                      'Unit',
                                                      'BioAssayMapping',
                                                      'BioAssayDatum',
                                                      'Describable',
                                                      'QuantitationTypeMapping',
                                                      'DesignElementMapping',
                                                      'FeatureLocation',
                                                      'FeatureDefect',
                                                      'BioDataValues',
                                                      'ArrayManufactureDeviation',
                                                      'PositionDelta',
                                                      'ZoneDefect',
                                                      'ParameterValue',
                                                      'SeqFeatureLocation',
                                                      'CompoundMeasurement',
                                                      'BioMaterialMeasurement',
                                                      'SequencePosition'
                                                    ],
                                    'parent' => undef,
                                    'documentation' => 'Abstract class that specifies for subclasses an association to NameValueTypes.  These can be used, for instance, to specify proprietary properties and in-house processing hints.',
                                    'attrs' => [],
                                    'associations' => [
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'propertySets',
                                                                       'documentation' => 'Allows specification of name/value pairs.  Meant to primarily help in-house, pipeline processing of instances by providing a place for values that aren\'t part of the specification proper.',
                                                                       'class_id' => 'S.6',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 1',
                                                                                         'rank' => '1'
                                                                                       },
                                                                       'class_name' => 'NameValueType'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'Allows specification of name/value pairs.  Meant to primarily help in-house, pipeline processing of instances by providing a place for values that aren\'t part of the specification proper.',
                                                                      'class_id' => 'S.5',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'Extendable'
                                                                    }
                                                        }
                                                      ],
                                    'abstract' => 'true',
                                    'methods' => [],
                                    'id' => 'S.5',
                                    'package' => 'MAGE',
                                    'name' => 'Extendable'
                                  },
                  'CompositePosition' => {
                                           'parent' => 'SequencePosition',
                                           'documentation' => 'The location in the compositeSequence target\'s sequence to which a source compositeSequence maps.  The association to MismatchInformation allows the specification, usually for control purposes, of deviations from the CompositeSequence\'s BioMaterial.',
                                           'attrs' => [],
                                           'associations' => [
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'composite',
                                                                              'documentation' => 'A source CompositeSequence that is part of a target CompositeSequence',
                                                                              'class_id' => 'S.261',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 1',
                                                                                                'rank' => '1'
                                                                                              },
                                                                              'class_name' => 'CompositeSequence'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => undef,
                                                                             'documentation' => 'A source CompositeSequence that is part of a target CompositeSequence',
                                                                             'class_id' => 'S.260',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'false',
                                                                             'constraint' => undef,
                                                                             'class_name' => 'CompositePosition'
                                                                           }
                                                               },
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '0..N',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'mismatchInformation',
                                                                              'documentation' => 'Differences in how the contained compositeSequence matches its target compositeSequence\'s sequence.',
                                                                              'class_id' => 'S.263',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 2',
                                                                                                'rank' => '2'
                                                                                              },
                                                                              'class_name' => 'MismatchInformation'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => undef,
                                                                             'documentation' => 'Differences in how the contained compositeSequence matches its target compositeSequence\'s sequence.',
                                                                             'class_id' => 'S.260',
                                                                             'aggregation' => 'composite',
                                                                             'navigable' => 'false',
                                                                             'constraint' => undef,
                                                                             'class_name' => 'CompositePosition'
                                                                           }
                                                               }
                                                             ],
                                           'abstract' => 'false',
                                           'methods' => [],
                                           'id' => 'S.260',
                                           'package' => 'DesignElement',
                                           'name' => 'CompositePosition'
                                         },
                  'Node' => {
                              'parent' => 'Describable',
                              'documentation' => 'An individual component of a clustering.  May contain other nodes.',
                              'attrs' => [],
                              'associations' => [
                                                  {
                                                    'other' => {
                                                                 'cardinality' => '0..N',
                                                                 'ordering' => 'unordered',
                                                                 'name' => 'nodes',
                                                                 'documentation' => 'Nested nodes of the BioAssayDataCluster.',
                                                                 'class_id' => 'S.83',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'true',
                                                                 'constraint' => {
                                                                                   'ordered' => 0,
                                                                                   'constraint' => 'rank: 1',
                                                                                   'rank' => '1'
                                                                                 },
                                                                 'class_name' => 'Node'
                                                               },
                                                    'self' => {
                                                                'cardinality' => '1',
                                                                'ordering' => 'unordered',
                                                                'name' => undef,
                                                                'documentation' => 'Nested nodes of the BioAssayDataCluster.',
                                                                'class_id' => 'S.83',
                                                                'aggregation' => 'composite',
                                                                'navigable' => 'false',
                                                                'constraint' => undef,
                                                                'class_name' => 'Node'
                                                              }
                                                  },
                                                  {
                                                    'other' => {
                                                                 'cardinality' => '0..N',
                                                                 'ordering' => 'unordered',
                                                                 'name' => 'nodeContents',
                                                                 'documentation' => 'The contents of the node, expressed as either a one, two or three dimensional object.',
                                                                 'class_id' => 'S.84',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'true',
                                                                 'constraint' => {
                                                                                   'ordered' => 0,
                                                                                   'constraint' => 'rank: 2',
                                                                                   'rank' => '2'
                                                                                 },
                                                                 'class_name' => 'NodeContents'
                                                               },
                                                    'self' => {
                                                                'cardinality' => '1',
                                                                'ordering' => 'unordered',
                                                                'name' => undef,
                                                                'documentation' => 'The contents of the node, expressed as either a one, two or three dimensional object.',
                                                                'class_id' => 'S.83',
                                                                'aggregation' => 'composite',
                                                                'navigable' => 'false',
                                                                'constraint' => undef,
                                                                'class_name' => 'Node'
                                                              }
                                                  },
                                                  {
                                                    'other' => {
                                                                 'cardinality' => '0..N',
                                                                 'ordering' => 'unordered',
                                                                 'name' => 'nodeValue',
                                                                 'documentation' => 'Values or measurements for this node that may be produced by the clustering algorithm.  Typical are distance values for the nodes.',
                                                                 'class_id' => 'S.85',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'true',
                                                                 'constraint' => {
                                                                                   'ordered' => 0,
                                                                                   'constraint' => 'rank: 3',
                                                                                   'rank' => '3'
                                                                                 },
                                                                 'class_name' => 'NodeValue'
                                                               },
                                                    'self' => {
                                                                'cardinality' => '1',
                                                                'ordering' => 'unordered',
                                                                'name' => undef,
                                                                'documentation' => 'Values or measurements for this node that may be produced by the clustering algorithm.  Typical are distance values for the nodes.',
                                                                'class_id' => 'S.83',
                                                                'aggregation' => 'composite',
                                                                'navigable' => 'false',
                                                                'constraint' => undef,
                                                                'class_name' => 'Node'
                                                              }
                                                  }
                                                ],
                              'abstract' => 'false',
                              'methods' => [],
                              'id' => 'S.83',
                              'package' => 'HigherLevelAnalysis',
                              'name' => 'Node'
                            },
                  'ManufactureLIMSBiomaterial' => {
                                                    'parent' => 'ManufactureLIMS',
                                                    'documentation' => 'Stores the location from which a biomaterial was obtained.',
                                                    'attrs' => [
                                                                 {
                                                                   'documentation' => 'The plate from which a biomaterial was obtained.',
                                                                   'id' => 'S.63',
                                                                   'type' => 'String',
                                                                   'name' => 'bioMaterialPlateIdentifier'
                                                                 },
                                                                 {
                                                                   'documentation' => 'The plate row from which a biomaterial was obtained.  Specified by a letter.',
                                                                   'id' => 'S.64',
                                                                   'type' => 'String',
                                                                   'name' => 'bioMaterialPlateRow'
                                                                 },
                                                                 {
                                                                   'documentation' => 'The plate column from which a biomaterial was obtained.  Specified by a number.',
                                                                   'id' => 'S.65',
                                                                   'type' => 'String',
                                                                   'name' => 'bioMaterialPlateCol'
                                                                 }
                                                               ],
                                                    'associations' => [],
                                                    'abstract' => 'false',
                                                    'methods' => [],
                                                    'id' => 'S.62',
                                                    'package' => 'Array',
                                                    'name' => 'ManufactureLIMSBiomaterial'
                                                  },
                  'TimeUnit' => {
                                  'parent' => 'Unit',
                                  'documentation' => 'Time',
                                  'attrs' => [
                                               {
                                                 'id' => 'S.198',
                                                 'type' => 'enum {years,months,weeks,d,h,m,s,us,other}',
                                                 'name' => 'unitNameCV'
                                               }
                                             ],
                                  'associations' => [],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.197',
                                  'package' => 'Measurement',
                                  'name' => 'TimeUnit'
                                },
                  'FactorValue' => {
                                     'parent' => 'Identifiable',
                                     'documentation' => 'The value for a ExperimentalFactor',
                                     'attrs' => [],
                                     'associations' => [
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'experimentalFactor',
                                                                        'documentation' => 'The pairing of BioAssay FactorValues with the ExperimentDesign ExperimentFactor.',
                                                                        'class_id' => 'S.146',
                                                                        'aggregation' => 'composite',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'ExperimentalFactor'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'factorValues',
                                                                       'documentation' => 'The pairing of BioAssay FactorValues with the ExperimentDesign ExperimentFactor.',
                                                                       'class_id' => 'S.147',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 2',
                                                                                         'rank' => '2'
                                                                                       },
                                                                       'class_name' => 'FactorValue'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'measurement',
                                                                        'documentation' => 'The measured value for this factor.',
                                                                        'class_id' => 'S.190',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'Measurement'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The measured value for this factor.',
                                                                       'class_id' => 'S.147',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'FactorValue'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'value',
                                                                        'documentation' => 'Allows a more complex value to be specified for a FactorValue than a simple Measurement.',
                                                                        'class_id' => 'S.185',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'OntologyEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Allows a more complex value to be specified for a FactorValue than a simple Measurement.',
                                                                       'class_id' => 'S.147',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'FactorValue'
                                                                     }
                                                         }
                                                       ],
                                     'abstract' => 'false',
                                     'methods' => [],
                                     'id' => 'S.147',
                                     'package' => 'Experiment',
                                     'name' => 'FactorValue'
                                   },
                  'MeasuredBioAssayData' => {
                                              'parent' => 'BioAssayData',
                                              'documentation' => 'The data associated with the MeasuredBioAssay produced by FeatureExtraction.',
                                              'attrs' => [],
                                              'associations' => [],
                                              'abstract' => 'false',
                                              'methods' => [],
                                              'id' => 'S.127',
                                              'package' => 'BioAssayData',
                                              'name' => 'MeasuredBioAssayData'
                                            },
                  'Protocol' => {
                                  'parent' => 'Parameterizable',
                                  'documentation' => 'A Protocol is a parameterizable description of a method.  ProtocolApplication is used to specify the ParameterValues of it\'s Protocol\'s Parameters.',
                                  'attrs' => [
                                               {
                                                 'documentation' => 'The text description of the Protocol.',
                                                 'id' => 'S.150',
                                                 'type' => 'String',
                                                 'name' => 'text'
                                               },
                                               {
                                                 'documentation' => 'The title of the Protocol',
                                                 'id' => 'S.151',
                                                 'type' => 'String',
                                                 'name' => 'title'
                                               }
                                             ],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'softwares',
                                                                     'documentation' => 'Software used by this Protocol.',
                                                                     'class_id' => 'S.157',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 3',
                                                                                       'rank' => '3'
                                                                                     },
                                                                     'class_name' => 'Software'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Software used by this Protocol.',
                                                                    'class_id' => 'S.149',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Protocol'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'hardwares',
                                                                     'documentation' => 'Hardware used by this protocol.',
                                                                     'class_id' => 'S.158',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 2',
                                                                                       'rank' => '2'
                                                                                     },
                                                                     'class_name' => 'Hardware'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Hardware used by this protocol.',
                                                                    'class_id' => 'S.149',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Protocol'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'type',
                                                                     'documentation' => 'The type of a Protocol,  a user should provide/use a recommended vocabulary.  Examples of types include:  RNA extraction, array washing, etc...',
                                                                     'class_id' => 'S.185',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'OntologyEntry'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The type of a Protocol,  a user should provide/use a recommended vocabulary.  Examples of types include:  RNA extraction, array washing, etc...',
                                                                    'class_id' => 'S.149',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Protocol'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.149',
                                  'package' => 'Protocol',
                                  'name' => 'Protocol'
                                },
                  'Parameter' => {
                                   'parent' => 'Identifiable',
                                   'documentation' => 'A Parameter is a replaceable value in a Parameterizable class.  Examples of Parameters include: scanning wavelength, laser power, centrifuge speed, multiplicative errors, the number of input nodes to a SOM, and PCR temperatures.  ',
                                   'attrs' => [],
                                   'associations' => [
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'dataType',
                                                                      'documentation' => 'The type of data generated by the parameter i.e. Boolean, float, etc...',
                                                                      'class_id' => 'S.185',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 2',
                                                                                        'rank' => '2'
                                                                                      },
                                                                      'class_name' => 'OntologyEntry'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The type of data generated by the parameter i.e. Boolean, float, etc...',
                                                                     'class_id' => 'S.152',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'Parameter'
                                                                   }
                                                       },
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'defaultValue',
                                                                      'documentation' => 'Allows the optional specification of a default values and the unit for the Parameter',
                                                                      'class_id' => 'S.190',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 1',
                                                                                        'rank' => '1'
                                                                                      },
                                                                      'class_name' => 'Measurement'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'Allows the optional specification of a default values and the unit for the Parameter',
                                                                     'class_id' => 'S.152',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'Parameter'
                                                                   }
                                                       }
                                                     ],
                                   'abstract' => 'false',
                                   'methods' => [],
                                   'id' => 'S.152',
                                   'package' => 'Protocol',
                                   'name' => 'Parameter'
                                 },
                  'ExperimentDesign' => {
                                          'parent' => 'Describable',
                                          'documentation' => 'The ExperimentDesign is the description and collection of ExperimentalFactors and the hierarchy of BioAssays to which they pertain.',
                                          'attrs' => [],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'topLevelBioAssays',
                                                                             'documentation' => 'The organization of the BioAssays as specified by the ExperimentDesign (TimeCourse, Dosage, etc.)',
                                                                             'class_id' => 'S.93',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 2',
                                                                                               'rank' => '2'
                                                                                             },
                                                                             'class_name' => 'BioAssay'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '0..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The organization of the BioAssays as specified by the ExperimentDesign (TimeCourse, Dosage, etc.)',
                                                                            'class_id' => 'S.145',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ExperimentDesign'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'experimentalFactors',
                                                                             'documentation' => 'The description of the factors (TimeCourse, Dosage, etc.) that group the BioAssays.',
                                                                             'class_id' => 'S.146',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 3',
                                                                                               'rank' => '3'
                                                                                             },
                                                                             'class_name' => 'ExperimentalFactor'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The description of the factors (TimeCourse, Dosage, etc.) that group the BioAssays.',
                                                                            'class_id' => 'S.145',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ExperimentDesign'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'replicateDescription',
                                                                             'documentation' => 'Description of the replicate strategy of the Experiment.',
                                                                             'class_id' => 'S.170',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 6',
                                                                                               'rank' => '6'
                                                                                             },
                                                                             'class_name' => 'Description'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'Description of the replicate strategy of the Experiment.',
                                                                            'class_id' => 'S.145',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ExperimentDesign'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'qualityControlDescription',
                                                                             'documentation' => 'Description of the quality control aspects of the Experiment.',
                                                                             'class_id' => 'S.170',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 4',
                                                                                               'rank' => '4'
                                                                                             },
                                                                             'class_name' => 'Description'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'Description of the quality control aspects of the Experiment.',
                                                                            'class_id' => 'S.145',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ExperimentDesign'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'normalizationDescription',
                                                                             'documentation' => 'Description of the normalization strategy of the Experiment.',
                                                                             'class_id' => 'S.170',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 5',
                                                                                               'rank' => '5'
                                                                                             },
                                                                             'class_name' => 'Description'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'Description of the normalization strategy of the Experiment.',
                                                                            'class_id' => 'S.145',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ExperimentDesign'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'types',
                                                                             'documentation' => 'Classification of an experiment.  For example \'normal vs. diseased\', \'treated vs. untreated\', \'time course\', \'tiling\', etc.',
                                                                             'class_id' => 'S.185',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'OntologyEntry'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'Classification of an experiment.  For example \'normal vs. diseased\', \'treated vs. untreated\', \'time course\', \'tiling\', etc.',
                                                                            'class_id' => 'S.145',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ExperimentDesign'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.145',
                                          'package' => 'Experiment',
                                          'name' => 'ExperimentDesign'
                                        },
                  'ExpectedValue' => {
                                       'parent' => 'ConfidenceIndicator',
                                       'documentation' => 'Indication of what value is expected of the associated standard quantitation type.',
                                       'attrs' => [],
                                       'associations' => [],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.248',
                                       'package' => 'QuantitationType',
                                       'name' => 'ExpectedValue'
                                     },
                  'ManufactureLIMS' => {
                                         'subclasses' => [
                                                           'ManufactureLIMSBiomaterial'
                                                         ],
                                         'parent' => 'Describable',
                                         'documentation' => 'Information on the physical production of arrays within the laboratory.',
                                         'attrs' => [
                                                      {
                                                        'documentation' => 'A brief description of the quality of the array manufacture process.',
                                                        'id' => 'S.61',
                                                        'type' => 'String',
                                                        'name' => 'quality'
                                                      }
                                                    ],
                                         'associations' => [
                                                             {
                                                               'other' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'feature',
                                                                            'documentation' => 'The feature whose LIMS information is being described.',
                                                                            'class_id' => 'S.262',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 1',
                                                                                              'rank' => '1'
                                                                                            },
                                                                            'class_name' => 'Feature'
                                                                          },
                                                               'self' => {
                                                                           'cardinality' => '0..N',
                                                                           'ordering' => 'unordered',
                                                                           'name' => undef,
                                                                           'documentation' => 'The feature whose LIMS information is being described.',
                                                                           'class_id' => 'S.60',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'false',
                                                                           'constraint' => undef,
                                                                           'class_name' => 'ManufactureLIMS'
                                                                         }
                                                             },
                                                             {
                                                               'other' => {
                                                                            'cardinality' => '0..1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'identifierLIMS',
                                                                            'documentation' => 'Association to a LIMS data source for further information on the manufacturing process.',
                                                                            'class_id' => 'S.173',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 3',
                                                                                              'rank' => '3'
                                                                                            },
                                                                            'class_name' => 'DatabaseEntry'
                                                                          },
                                                               'self' => {
                                                                           'cardinality' => '1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => undef,
                                                                           'documentation' => 'Association to a LIMS data source for further information on the manufacturing process.',
                                                                           'class_id' => 'S.60',
                                                                           'aggregation' => 'composite',
                                                                           'navigable' => 'false',
                                                                           'constraint' => undef,
                                                                           'class_name' => 'ManufactureLIMS'
                                                                         }
                                                             },
                                                             {
                                                               'other' => {
                                                                            'cardinality' => '0..1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'bioMaterial',
                                                                            'documentation' => 'The BioMaterial used for the feature.',
                                                                            'class_id' => 'S.72',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 2',
                                                                                              'rank' => '2'
                                                                                            },
                                                                            'class_name' => 'BioMaterial'
                                                                          },
                                                               'self' => {
                                                                           'cardinality' => '0..N',
                                                                           'ordering' => 'unordered',
                                                                           'name' => undef,
                                                                           'documentation' => 'The BioMaterial used for the feature.',
                                                                           'class_id' => 'S.60',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'false',
                                                                           'constraint' => undef,
                                                                           'class_name' => 'ManufactureLIMS'
                                                                         }
                                                             }
                                                           ],
                                         'abstract' => 'false',
                                         'methods' => [],
                                         'id' => 'S.60',
                                         'package' => 'Array',
                                         'name' => 'ManufactureLIMS'
                                       },
                  'FeatureDefect' => {
                                       'parent' => 'Extendable',
                                       'documentation' => 'Stores the defect information for a feature.',
                                       'attrs' => [],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '0..1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'positionDelta',
                                                                          'documentation' => 'How the feature deviates in position from the ArrayDesign.',
                                                                          'class_id' => 'S.66',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 2',
                                                                                            'rank' => '2'
                                                                                          },
                                                                          'class_name' => 'PositionDelta'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'How the feature deviates in position from the ArrayDesign.',
                                                                         'class_id' => 'S.45',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'FeatureDefect'
                                                                       }
                                                           },
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'feature',
                                                                          'documentation' => 'The feature that was manufactured defectively.',
                                                                          'class_id' => 'S.262',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 3',
                                                                                            'rank' => '3'
                                                                                          },
                                                                          'class_name' => 'Feature'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The feature that was manufactured defectively.',
                                                                         'class_id' => 'S.45',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'FeatureDefect'
                                                                       }
                                                           },
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'defectType',
                                                                          'documentation' => 'Indicates the type of defect (e.g. a missing feature or a moved feature).',
                                                                          'class_id' => 'S.185',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'OntologyEntry'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'Indicates the type of defect (e.g. a missing feature or a moved feature).',
                                                                         'class_id' => 'S.45',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'FeatureDefect'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.45',
                                       'package' => 'Array',
                                       'name' => 'FeatureDefect'
                                     },
                  'ReporterPosition' => {
                                          'parent' => 'SequencePosition',
                                          'documentation' => 'The location in the composite target\'s sequence to which a source reporter maps.  The association to MismatchInformation allows the specification, usually for control purposes, of deviations from the CompositeSequence\'s BioMaterial.',
                                          'attrs' => [],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'reporter',
                                                                             'documentation' => 'A reporter that comprises part of a CompositeSequence.',
                                                                             'class_id' => 'S.258',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'Reporter'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '0..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'A reporter that comprises part of a CompositeSequence.',
                                                                            'class_id' => 'S.259',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ReporterPosition'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'mismatchInformation',
                                                                             'documentation' => 'Differences in how the reporter matches its compositeSequence\'s sequence.',
                                                                             'class_id' => 'S.263',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 2',
                                                                                               'rank' => '2'
                                                                                             },
                                                                             'class_name' => 'MismatchInformation'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'Differences in how the reporter matches its compositeSequence\'s sequence.',
                                                                            'class_id' => 'S.259',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ReporterPosition'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.259',
                                          'package' => 'DesignElement',
                                          'name' => 'ReporterPosition'
                                        },
                  'BioDataTuples' => {
                                       'parent' => 'BioDataValues',
                                       'documentation' => 'A relational, tuple representation of the data.',
                                       'attrs' => [],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '0..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'bioAssayTupleData',
                                                                          'documentation' => 'The collection of BioAssayData tuples.',
                                                                          'class_id' => 'S.124',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'BioAssayDatum'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The collection of BioAssayData tuples.',
                                                                         'class_id' => 'S.134',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'BioDataTuples'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.134',
                                       'package' => 'BioAssayData',
                                       'name' => 'BioDataTuples'
                                     },
                  'BioAssayDataCluster' => {
                                             'parent' => 'Identifiable',
                                             'documentation' => 'A mathematical method of higher level analysis whereby BioAssayData are grouped together into nodes.',
                                             'attrs' => [],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '1..N',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'nodes',
                                                                                'documentation' => 'The nodes of the cluster.',
                                                                                'class_id' => 'S.83',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 2',
                                                                                                  'rank' => '2'
                                                                                                },
                                                                                'class_name' => 'Node'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The nodes of the cluster.',
                                                                               'class_id' => 'S.82',
                                                                               'aggregation' => 'composite',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'BioAssayDataCluster'
                                                                             }
                                                                 },
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'clusterBioAssayData',
                                                                                'documentation' => 'The BioAssayData whose values were used by the cluster algorithm.',
                                                                                'class_id' => 'S.120',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'BioAssayData'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The BioAssayData whose values were used by the cluster algorithm.',
                                                                               'class_id' => 'S.82',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'BioAssayDataCluster'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.82',
                                             'package' => 'HigherLevelAnalysis',
                                             'name' => 'BioAssayDataCluster'
                                           },
                  'SpecializedQuantitationType' => {
                                                     'parent' => 'QuantitationType',
                                                     'documentation' => 'User defined quantitation type.',
                                                     'attrs' => [],
                                                     'associations' => [],
                                                     'abstract' => 'false',
                                                     'methods' => [],
                                                     'id' => 'S.243',
                                                     'package' => 'QuantitationType',
                                                     'name' => 'SpecializedQuantitationType'
                                                   },
                  'BioEvent' => {
                                  'subclasses' => [
                                                    'BioAssayTreatment',
                                                    'BioAssayCreation',
                                                    'FeatureExtraction',
                                                    'Transformation',
                                                    'Map',
                                                    'Treatment'
                                                  ],
                                  'parent' => 'Identifiable',
                                  'documentation' => 'An abstract class to capture the concept of an event (either in the laboratory or a computational analysis).',
                                  'attrs' => [],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'protocolApplications',
                                                                     'documentation' => 'The applied protocols to the BioEvent.',
                                                                     'class_id' => 'S.155',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'ProtocolApplication'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The applied protocols to the BioEvent.',
                                                                    'class_id' => 'S.212',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'BioEvent'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'true',
                                  'methods' => [],
                                  'id' => 'S.212',
                                  'package' => 'BioEvent',
                                  'name' => 'BioEvent'
                                },
                  'Measurement' => {
                                     'parent' => 'Extendable',
                                     'documentation' => 'A Measurement is a quantity with a unit.',
                                     'attrs' => [
                                                  {
                                                    'documentation' => 'The type of measurement, for instance if the measurement is five feet, it can be either absolute (five feet tall) or change (five feet further along).',
                                                    'id' => 'S.191',
                                                    'type' => 'enum {absolute,change}',
                                                    'name' => 'type'
                                                  },
                                                  {
                                                    'documentation' => 'The value of the measurement.  kindCV (and otherKind) determine with Unit the datatype of value.',
                                                    'id' => 'S.192',
                                                    'type' => 'any',
                                                    'name' => 'value'
                                                  },
                                                  {
                                                    'documentation' => 'One of the enumeration values to determine the controlled vocabulary of the value.',
                                                    'id' => 'S.193',
                                                    'type' => 'enum {time,distance,temperature,quantity,mass,volume,concentration,other}',
                                                    'name' => 'kindCV'
                                                  },
                                                  {
                                                    'documentation' => 'Name of the controlled vocabulary if it isn\'t one of the Unit subclasses.',
                                                    'id' => 'S.194',
                                                    'type' => 'String',
                                                    'name' => 'otherKind'
                                                  }
                                                ],
                                     'associations' => [
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'unit',
                                                                        'documentation' => 'The Unit associated with the Measurement.',
                                                                        'class_id' => 'S.195',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'Unit'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The Unit associated with the Measurement.',
                                                                       'class_id' => 'S.190',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'Measurement'
                                                                     }
                                                         }
                                                       ],
                                     'abstract' => 'false',
                                     'methods' => [],
                                     'id' => 'S.190',
                                     'package' => 'Measurement',
                                     'name' => 'Measurement'
                                   },
                  'Compound' => {
                                  'parent' => 'Identifiable',
                                  'documentation' => 'A Compound can be a simple compound such as SDS (sodium dodecyl sulfate).  It may also be made of other Compounds in proportions using CompoundMeasurements to enumerate the Compounds and their amounts such as LB (Luria Broth) Media.',
                                  'attrs' => [
                                               {
                                                 'documentation' => 'A Compound may be a special case Solvent.',
                                                 'id' => 'S.76',
                                                 'type' => 'boolean',
                                                 'name' => 'isSolvent'
                                               }
                                             ],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'componentCompounds',
                                                                     'documentation' => 'The Compounds and their amounts used to create this Compound.',
                                                                     'class_id' => 'S.77',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 2',
                                                                                       'rank' => '2'
                                                                                     },
                                                                     'class_name' => 'CompoundMeasurement'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The Compounds and their amounts used to create this Compound.',
                                                                    'class_id' => 'S.75',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Compound'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'compoundIndices',
                                                                     'documentation' => 'Indices into common Compound Indices, such as the Merck Index, for this Compound.',
                                                                     'class_id' => 'S.185',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'OntologyEntry'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Indices into common Compound Indices, such as the Merck Index, for this Compound.',
                                                                    'class_id' => 'S.75',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Compound'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'externalLIMS',
                                                                     'documentation' => 'Reference to an entry in an external LIMS data source.',
                                                                     'class_id' => 'S.173',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 3',
                                                                                       'rank' => '3'
                                                                                     },
                                                                     'class_name' => 'DatabaseEntry'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Reference to an entry in an external LIMS data source.',
                                                                    'class_id' => 'S.75',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Compound'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.75',
                                  'package' => 'BioMaterial',
                                  'name' => 'Compound'
                                },
                  'SeqFeature' => {
                                    'parent' => 'Describable',
                                    'documentation' => 'Represents, in general, what would be a GenBank Feature Table annotation for a sequence.',
                                    'attrs' => [
                                                 {
                                                   'documentation' => 'How the evidence for a SeqFeature was determined.',
                                                   'id' => 'S.228',
                                                   'type' => 'enum {experimental, computational,both,unknown,NA}',
                                                   'name' => 'basis'
                                                 }
                                               ],
                                    'associations' => [
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'regions',
                                                                       'documentation' => 'Association to classes that describe the location with the sequence of the SeqFeature.',
                                                                       'class_id' => 'S.229',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 1',
                                                                                         'rank' => '1'
                                                                                       },
                                                                       'class_name' => 'SeqFeatureLocation'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'Association to classes that describe the location with the sequence of the SeqFeature.',
                                                                      'class_id' => 'S.227',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'SeqFeature'
                                                                    }
                                                        }
                                                      ],
                                    'abstract' => 'false',
                                    'methods' => [],
                                    'id' => 'S.227',
                                    'package' => 'BioSequence',
                                    'name' => 'SeqFeature'
                                  },
                  'ProtocolApplication' => {
                                             'parent' => 'ParameterizableApplication',
                                             'documentation' => 'The use of a protocol with the requisite Parameters and ParameterValues.',
                                             'attrs' => [
                                                          {
                                                            'documentation' => 'When the protocol was applied.',
                                                            'id' => 'S.156',
                                                            'type' => 'String',
                                                            'name' => 'activityDate'
                                                          }
                                                        ],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..N',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'performers',
                                                                                'documentation' => 'The people who performed the protocol.',
                                                                                'class_id' => 'S.102',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 3',
                                                                                                  'rank' => '3'
                                                                                                },
                                                                                'class_name' => 'Person'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The people who performed the protocol.',
                                                                               'class_id' => 'S.155',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'ProtocolApplication'
                                                                             }
                                                                 },
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'protocol',
                                                                                'documentation' => 'The protocol that is being used.',
                                                                                'class_id' => 'S.149',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 4',
                                                                                                  'rank' => '4'
                                                                                                },
                                                                                'class_name' => 'Protocol'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The protocol that is being used.',
                                                                               'class_id' => 'S.155',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'ProtocolApplication'
                                                                             }
                                                                 },
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..N',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'softwareApplications',
                                                                                'documentation' => 'The use of software for the application of the protocol.',
                                                                                'class_id' => 'S.163',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 2',
                                                                                                  'rank' => '2'
                                                                                                },
                                                                                'class_name' => 'SoftwareApplication'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The use of software for the application of the protocol.',
                                                                               'class_id' => 'S.155',
                                                                               'aggregation' => 'composite',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'ProtocolApplication'
                                                                             }
                                                                 },
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..N',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'hardwareApplications',
                                                                                'documentation' => 'The use of hardware for the application of the protocol.',
                                                                                'class_id' => 'S.161',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'HardwareApplication'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The use of hardware for the application of the protocol.',
                                                                               'class_id' => 'S.155',
                                                                               'aggregation' => 'composite',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'ProtocolApplication'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.155',
                                             'package' => 'Protocol',
                                             'name' => 'ProtocolApplication'
                                           },
                  'NodeContents' => {
                                      'parent' => 'Describable',
                                      'documentation' => 'The contents of a node for any or all of the three Dimensions.  If a node only contained genes just the DesignElementDimension would be defined.',
                                      'attrs' => [],
                                      'associations' => [
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'designElementDimension',
                                                                         'documentation' => 'The relevant DesignElements for this NodeContents from the BioAssayData.',
                                                                         'class_id' => 'S.123',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 2',
                                                                                           'rank' => '2'
                                                                                         },
                                                                         'class_name' => 'DesignElementDimension'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The relevant DesignElements for this NodeContents from the BioAssayData.',
                                                                        'class_id' => 'S.84',
                                                                        'aggregation' => 'aggregate',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'NodeContents'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'quantitationDimension',
                                                                         'documentation' => 'The relevant QuantitationTypes for this NodeContents from the BioAssayData.',
                                                                         'class_id' => 'S.121',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 3',
                                                                                           'rank' => '3'
                                                                                         },
                                                                         'class_name' => 'QuantitationTypeDimension'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The relevant QuantitationTypes for this NodeContents from the BioAssayData.',
                                                                        'class_id' => 'S.84',
                                                                        'aggregation' => 'aggregate',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'NodeContents'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'bioAssayDimension',
                                                                         'documentation' => 'The relevant BioAssays for this NodeContents from the BioAssayData.',
                                                                         'class_id' => 'S.135',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 1',
                                                                                           'rank' => '1'
                                                                                         },
                                                                         'class_name' => 'BioAssayDimension'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The relevant BioAssays for this NodeContents from the BioAssayData.',
                                                                        'class_id' => 'S.84',
                                                                        'aggregation' => 'aggregate',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'NodeContents'
                                                                      }
                                                          }
                                                        ],
                                      'abstract' => 'false',
                                      'methods' => [],
                                      'id' => 'S.84',
                                      'package' => 'HigherLevelAnalysis',
                                      'name' => 'NodeContents'
                                    },
                  'StandardQuantitationType' => {
                                                  'subclasses' => [
                                                                    'DerivedSignal',
                                                                    'MeasuredSignal',
                                                                    'Ratio',
                                                                    'ConfidenceIndicator',
                                                                    'PresentAbsent',
                                                                    'Failed'
                                                                  ],
                                                  'parent' => 'QuantitationType',
                                                  'documentation' => 'Superclass for the named quantitation type.  Useful for mapping to those languages that can use a fly-weight for processing the subclasses.',
                                                  'attrs' => [],
                                                  'associations' => [],
                                                  'abstract' => 'true',
                                                  'methods' => [],
                                                  'id' => 'S.240',
                                                  'package' => 'QuantitationType',
                                                  'name' => 'StandardQuantitationType'
                                                },
                  'ConcentrationUnit' => {
                                           'parent' => 'Unit',
                                           'documentation' => 'Concentration',
                                           'attrs' => [
                                                        {
                                                          'id' => 'S.210',
                                                          'type' => 'enum {M,mM,uM,nM,pM,fM,mg/mL,mL/L,g/L,gram_percent,mass/volume_percent, mass/mass_percent,other}',
                                                          'name' => 'unitNameCV'
                                                        }
                                                      ],
                                           'associations' => [],
                                           'abstract' => 'false',
                                           'methods' => [],
                                           'id' => 'S.209',
                                           'package' => 'Measurement',
                                           'name' => 'ConcentrationUnit'
                                         },
                  'ArrayManufactureDeviation' => {
                                                   'parent' => 'Extendable',
                                                   'documentation' => 'Stores information of the potential difference between an array design and arrays that have been manufactured using that design (e.g. a tip failed to print several spots).',
                                                   'attrs' => [],
                                                   'associations' => [
                                                                       {
                                                                         'other' => {
                                                                                      'cardinality' => '0..N',
                                                                                      'ordering' => 'unordered',
                                                                                      'name' => 'featureDefects',
                                                                                      'documentation' => 'Description on features who are manufactured in a different location than specified in the ArrayDesign.',
                                                                                      'class_id' => 'S.45',
                                                                                      'aggregation' => 'none',
                                                                                      'navigable' => 'true',
                                                                                      'constraint' => {
                                                                                                        'ordered' => 0,
                                                                                                        'constraint' => 'rank: 2',
                                                                                                        'rank' => '2'
                                                                                                      },
                                                                                      'class_name' => 'FeatureDefect'
                                                                                    },
                                                                         'self' => {
                                                                                     'cardinality' => '1',
                                                                                     'ordering' => 'unordered',
                                                                                     'name' => undef,
                                                                                     'documentation' => 'Description on features who are manufactured in a different location than specified in the ArrayDesign.',
                                                                                     'class_id' => 'S.58',
                                                                                     'aggregation' => 'composite',
                                                                                     'navigable' => 'false',
                                                                                     'constraint' => undef,
                                                                                     'class_name' => 'ArrayManufactureDeviation'
                                                                                   }
                                                                       },
                                                                       {
                                                                         'other' => {
                                                                                      'cardinality' => '0..N',
                                                                                      'ordering' => 'unordered',
                                                                                      'name' => 'adjustments',
                                                                                      'documentation' => 'Descriptions of how a Zone has been printed differently than specified in the ArrayDesign.',
                                                                                      'class_id' => 'S.69',
                                                                                      'aggregation' => 'none',
                                                                                      'navigable' => 'true',
                                                                                      'constraint' => {
                                                                                                        'ordered' => 0,
                                                                                                        'constraint' => 'rank: 1',
                                                                                                        'rank' => '1'
                                                                                                      },
                                                                                      'class_name' => 'ZoneDefect'
                                                                                    },
                                                                         'self' => {
                                                                                     'cardinality' => '1',
                                                                                     'ordering' => 'unordered',
                                                                                     'name' => undef,
                                                                                     'documentation' => 'Descriptions of how a Zone has been printed differently than specified in the ArrayDesign.',
                                                                                     'class_id' => 'S.58',
                                                                                     'aggregation' => 'composite',
                                                                                     'navigable' => 'false',
                                                                                     'constraint' => undef,
                                                                                     'class_name' => 'ArrayManufactureDeviation'
                                                                                   }
                                                                       }
                                                                     ],
                                                   'abstract' => 'false',
                                                   'methods' => [],
                                                   'id' => 'S.58',
                                                   'package' => 'Array',
                                                   'name' => 'ArrayManufactureDeviation'
                                                 },
                  'BioAssayTreatment' => {
                                           'subclasses' => [
                                                             'ImageAcquisition'
                                                           ],
                                           'parent' => 'BioEvent',
                                           'documentation' => 'The event which records the process by which PhysicalBioAssays are processed (typically washing, blocking, etc...).',
                                           'attrs' => [],
                                           'associations' => [
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'physicalBioAssay',
                                                                              'documentation' => 'The set of treatments undergone by this PhysicalBioAssay.',
                                                                              'class_id' => 'S.89',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 1',
                                                                                                'rank' => '1'
                                                                                              },
                                                                              'class_name' => 'PhysicalBioAssay'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'bioAssayTreatments',
                                                                             'documentation' => 'The set of treatments undergone by this PhysicalBioAssay.',
                                                                             'class_id' => 'S.100',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 1,
                                                                                               'constraint' => 'ordered rank: 3',
                                                                                               'rank' => '3'
                                                                                             },
                                                                             'class_name' => 'BioAssayTreatment'
                                                                           }
                                                               },
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'target',
                                                                              'documentation' => 'The PhysicalBioAssay that was treated.',
                                                                              'class_id' => 'S.89',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 2',
                                                                                                'rank' => '2'
                                                                                              },
                                                                              'class_name' => 'PhysicalBioAssay'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => undef,
                                                                             'documentation' => 'The PhysicalBioAssay that was treated.',
                                                                             'class_id' => 'S.100',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'false',
                                                                             'constraint' => undef,
                                                                             'class_name' => 'BioAssayTreatment'
                                                                           }
                                                               }
                                                             ],
                                           'abstract' => 'false',
                                           'methods' => [],
                                           'id' => 'S.100',
                                           'package' => 'BioAssay',
                                           'name' => 'BioAssayTreatment'
                                         },
                  'TemperatureUnit' => {
                                         'parent' => 'Unit',
                                         'documentation' => 'Temperature',
                                         'attrs' => [
                                                      {
                                                        'id' => 'S.202',
                                                        'type' => 'enum {degree_C,degree_F,K}',
                                                        'name' => 'unitNameCV'
                                                      }
                                                    ],
                                         'associations' => [],
                                         'abstract' => 'false',
                                         'methods' => [],
                                         'id' => 'S.201',
                                         'package' => 'Measurement',
                                         'name' => 'TemperatureUnit'
                                       },
                  'DerivedBioAssayData' => {
                                             'parent' => 'BioAssayData',
                                             'documentation' => 'The output of a transformation event.',
                                             'attrs' => [],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'producerTransformation',
                                                                                'documentation' => 'The association between the DerivedBioAssayData and the Transformation event that produced it.',
                                                                                'class_id' => 'S.137',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'Transformation'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'derivedBioAssayDataTarget',
                                                                               'documentation' => 'The association between the DerivedBioAssayData and the Transformation event that produced it.',
                                                                               'class_id' => 'S.126',
                                                                               'aggregation' => 'composite',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 2',
                                                                                                 'rank' => '2'
                                                                                               },
                                                                               'class_name' => 'DerivedBioAssayData'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.126',
                                             'package' => 'BioAssayData',
                                             'name' => 'DerivedBioAssayData'
                                           },
                  'ConfidenceIndicator' => {
                                             'subclasses' => [
                                                               'Error',
                                                               'PValue',
                                                               'ExpectedValue'
                                                             ],
                                             'parent' => 'StandardQuantitationType',
                                             'documentation' => 'Indication of some measure of confidence for a standard quantitation type.',
                                             'attrs' => [],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'targetQuantitationType',
                                                                                'documentation' => 'The association between a ConfidenceIndicator and the QuantitationType its is an indicator for.',
                                                                                'class_id' => 'S.241',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'QuantitationType'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'confidenceIndicators',
                                                                               'documentation' => 'The association between a ConfidenceIndicator and the QuantitationType its is an indicator for.',
                                                                               'class_id' => 'S.250',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 4',
                                                                                                 'rank' => '4'
                                                                                               },
                                                                               'class_name' => 'ConfidenceIndicator'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'true',
                                             'methods' => [],
                                             'id' => 'S.250',
                                             'package' => 'QuantitationType',
                                             'name' => 'ConfidenceIndicator'
                                           },
                  'Treatment' => {
                                   'parent' => 'BioEvent',
                                   'documentation' => 'The process by which a biomaterial is created (from source biomaterials).  Treatments have an order and an action.',
                                   'attrs' => [
                                                {
                                                  'documentation' => 'The chronological order in which a treatment occurred (in relation to other treatments).  More than one treatment can have the same chronological order indicating that they happened (or were caused to happen) simultaneously.',
                                                  'id' => 'S.80',
                                                  'type' => 'int',
                                                  'name' => 'order'
                                                }
                                              ],
                                   'associations' => [
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'compoundMeasurements',
                                                                      'documentation' => 'The compounds and their amounts used in the treatment.',
                                                                      'class_id' => 'S.77',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 3',
                                                                                        'rank' => '3'
                                                                                      },
                                                                      'class_name' => 'CompoundMeasurement'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The compounds and their amounts used in the treatment.',
                                                                     'class_id' => 'S.79',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'Treatment'
                                                                   }
                                                       },
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'sourceBioMaterialMeasurements',
                                                                      'documentation' => 'The BioMaterials and the amounts used in the treatment',
                                                                      'class_id' => 'S.78',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 4',
                                                                                        'rank' => '4'
                                                                                      },
                                                                      'class_name' => 'BioMaterialMeasurement'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The BioMaterials and the amounts used in the treatment',
                                                                     'class_id' => 'S.79',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'Treatment'
                                                                   }
                                                       },
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'actionMeasurement',
                                                                      'documentation' => 'Measures events like duration, centrifuge speed, etc.',
                                                                      'class_id' => 'S.190',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 2',
                                                                                        'rank' => '2'
                                                                                      },
                                                                      'class_name' => 'Measurement'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'Measures events like duration, centrifuge speed, etc.',
                                                                     'class_id' => 'S.79',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'Treatment'
                                                                   }
                                                       },
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'action',
                                                                      'documentation' => 'The event that occurred (e.g. grow, wait, add, etc...).  The actions should be a recommended vocabulary',
                                                                      'class_id' => 'S.185',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 1',
                                                                                        'rank' => '1'
                                                                                      },
                                                                      'class_name' => 'OntologyEntry'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The event that occurred (e.g. grow, wait, add, etc...).  The actions should be a recommended vocabulary',
                                                                     'class_id' => 'S.79',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'Treatment'
                                                                   }
                                                       }
                                                     ],
                                   'abstract' => 'false',
                                   'methods' => [],
                                   'id' => 'S.79',
                                   'package' => 'BioMaterial',
                                   'name' => 'Treatment'
                                 },
                  'VolumeUnit' => {
                                    'parent' => 'Unit',
                                    'documentation' => 'Volume',
                                    'attrs' => [
                                                 {
                                                   'id' => 'S.208',
                                                   'type' => 'enum {mL,cc,dL,L,uL,nL,pL,fL,other}',
                                                   'name' => 'unitNameCV'
                                                 }
                                               ],
                                    'associations' => [],
                                    'abstract' => 'false',
                                    'methods' => [],
                                    'id' => 'S.207',
                                    'package' => 'Measurement',
                                    'name' => 'VolumeUnit'
                                  },
                  'Identifiable' => {
                                      'subclasses' => [
                                                        'QuantitationType',
                                                        'ArrayDesign',
                                                        'Database',
                                                        'Image',
                                                        'BioAssay',
                                                        'Channel',
                                                        'Security',
                                                        'DesignElement',
                                                        'Zone',
                                                        'SecurityGroup',
                                                        'Contact',
                                                        'DesignElementGroup',
                                                        'BioAssayData',
                                                        'QuantitationTypeDimension',
                                                        'DesignElementDimension',
                                                        'Array',
                                                        'ArrayGroup',
                                                        'BioAssayDimension',
                                                        'ArrayManufacture',
                                                        'BioEvent',
                                                        'Experiment',
                                                        'ExperimentalFactor',
                                                        'FactorValue',
                                                        'Parameter',
                                                        'BioMaterial',
                                                        'Compound',
                                                        'BioSequence',
                                                        'Parameterizable',
                                                        'BioAssayDataCluster'
                                                      ],
                                      'parent' => 'Describable',
                                      'documentation' => 'An Identifiable class is one that has an unambiguous reference within the scope.  It also has a potentially ambiguous name.',
                                      'attrs' => [
                                                   {
                                                     'documentation' => 'An identifier is an unambiguous string that is unique within the scope (i.e. a document, a set of related documents, or a repository) of its use.',
                                                     'id' => 'S.3',
                                                     'type' => 'String',
                                                     'name' => 'identifier'
                                                   },
                                                   {
                                                     'documentation' => 'The potentially ambiguous common identifier.',
                                                     'id' => 'S.4',
                                                     'type' => 'String',
                                                     'name' => 'name'
                                                   }
                                                 ],
                                      'associations' => [],
                                      'abstract' => 'true',
                                      'methods' => [],
                                      'id' => 'S.2',
                                      'package' => 'MAGE',
                                      'name' => 'Identifiable'
                                    },
                  'FeatureExtraction' => {
                                           'parent' => 'BioEvent',
                                           'documentation' => 'The process by which data is extracted from an image producing a measuredBioAssayData and a measuredBioAssay.',
                                           'attrs' => [],
                                           'associations' => [
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'physicalBioAssaySource',
                                                                              'documentation' => 'The PhysicalBioAssay used in the FeatureExtraction event.',
                                                                              'class_id' => 'S.89',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 1',
                                                                                                'rank' => '1'
                                                                                              },
                                                                              'class_name' => 'PhysicalBioAssay'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => undef,
                                                                             'documentation' => 'The PhysicalBioAssay used in the FeatureExtraction event.',
                                                                             'class_id' => 'S.97',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'false',
                                                                             'constraint' => undef,
                                                                             'class_name' => 'FeatureExtraction'
                                                                           }
                                                               },
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'measuredBioAssayTarget',
                                                                              'documentation' => 'The association between the MeasuredBioAssay and the FeatureExtraction Event.',
                                                                              'class_id' => 'S.95',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 2',
                                                                                                'rank' => '2'
                                                                                              },
                                                                              'class_name' => 'MeasuredBioAssay'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '0..1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'featureExtraction',
                                                                             'documentation' => 'The association between the MeasuredBioAssay and the FeatureExtraction Event.',
                                                                             'class_id' => 'S.97',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'FeatureExtraction'
                                                                           }
                                                               }
                                                             ],
                                           'abstract' => 'false',
                                           'methods' => [],
                                           'id' => 'S.97',
                                           'package' => 'BioAssay',
                                           'name' => 'FeatureExtraction'
                                         },
                  'BioDataCube' => {
                                     'parent' => 'BioDataValues',
                                     'documentation' => 'A three-dimensional cube representation of the data.',
                                     'attrs' => [
                                                  {
                                                    'documentation' => 'Three dimension array, indexed by the three dimensions to provide the data for the BioAssayData.',
                                                    'id' => 'S.131',
                                                    'type' => 'any[][][]',
                                                    'name' => 'cube'
                                                  },
                                                  {
                                                    'documentation' => 'The order to expect the dimension.  The enumeration uses the first letter of the three dimensions to represent the six possible orderings.',
                                                    'id' => 'S.132',
                                                    'type' => 'enum {BDQ,BQD,DBQ,DQB,QBD,QDB}',
                                                    'name' => 'order'
                                                  }
                                                ],
                                     'associations' => [],
                                     'abstract' => 'false',
                                     'methods' => [],
                                     'id' => 'S.130',
                                     'package' => 'BioAssayData',
                                     'name' => 'BioDataCube'
                                   },
                  'SoftwareApplication' => {
                                             'parent' => 'ParameterizableApplication',
                                             'documentation' => 'The use of a piece of software with the requisite Parameters and ParameterValues.',
                                             'attrs' => [
                                                          {
                                                            'documentation' => 'The version of the software.',
                                                            'id' => 'S.164',
                                                            'type' => 'String',
                                                            'name' => 'version'
                                                          },
                                                          {
                                                            'documentation' => 'When the software was released.',
                                                            'id' => 'S.165',
                                                            'type' => 'Date',
                                                            'name' => 'releaseDate'
                                                          }
                                                        ],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'software',
                                                                                'documentation' => 'The underlying software.',
                                                                                'class_id' => 'S.157',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'Software'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The underlying software.',
                                                                               'class_id' => 'S.163',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'SoftwareApplication'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.163',
                                             'package' => 'Protocol',
                                             'name' => 'SoftwareApplication'
                                           },
                  'Hybridization' => {
                                       'parent' => 'BioAssayCreation',
                                       'documentation' => 'The archetypal bioAssayCreation event, whereby biomaterials are hybridized to an array.',
                                       'attrs' => [],
                                       'associations' => [],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.98',
                                       'package' => 'BioAssay',
                                       'name' => 'Hybridization'
                                     },
                  'BioAssayDimension' => {
                                           'parent' => 'Identifiable',
                                           'documentation' => 'An ordered list of bioAssays.',
                                           'attrs' => [],
                                           'associations' => [
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '0..N',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'bioAssays',
                                                                              'documentation' => 'The BioAssays for this Dimension',
                                                                              'class_id' => 'S.93',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 1,
                                                                                                'constraint' => 'ordered rank: 1',
                                                                                                'rank' => '1'
                                                                                              },
                                                                              'class_name' => 'BioAssay'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => undef,
                                                                             'documentation' => 'The BioAssays for this Dimension',
                                                                             'class_id' => 'S.135',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'false',
                                                                             'constraint' => undef,
                                                                             'class_name' => 'BioAssayDimension'
                                                                           }
                                                               }
                                                             ],
                                           'abstract' => 'false',
                                           'methods' => [],
                                           'id' => 'S.135',
                                           'package' => 'BioAssayData',
                                           'name' => 'BioAssayDimension'
                                         },
                  'CompositeSequenceDimension' => {
                                                    'parent' => 'DesignElementDimension',
                                                    'documentation' => 'Specialized DesignElementDimension to hold CompositeSequences.',
                                                    'attrs' => [],
                                                    'associations' => [
                                                                        {
                                                                          'other' => {
                                                                                       'cardinality' => '0..N',
                                                                                       'ordering' => 'unordered',
                                                                                       'name' => 'compositeSequences',
                                                                                       'documentation' => 'The CompositeSequences for this Dimension.',
                                                                                       'class_id' => 'S.261',
                                                                                       'aggregation' => 'none',
                                                                                       'navigable' => 'true',
                                                                                       'constraint' => {
                                                                                                         'ordered' => 1,
                                                                                                         'constraint' => 'ordered rank: 1',
                                                                                                         'rank' => '1'
                                                                                                       },
                                                                                       'class_name' => 'CompositeSequence'
                                                                                     },
                                                                          'self' => {
                                                                                      'cardinality' => '0..N',
                                                                                      'ordering' => 'unordered',
                                                                                      'name' => undef,
                                                                                      'documentation' => 'The CompositeSequences for this Dimension.',
                                                                                      'class_id' => 'S.140',
                                                                                      'aggregation' => 'none',
                                                                                      'navigable' => 'false',
                                                                                      'constraint' => undef,
                                                                                      'class_name' => 'CompositeSequenceDimension'
                                                                                    }
                                                                        }
                                                                      ],
                                                    'abstract' => 'false',
                                                    'methods' => [],
                                                    'id' => 'S.140',
                                                    'package' => 'BioAssayData',
                                                    'name' => 'CompositeSequenceDimension'
                                                  },
                  'DerivedSignal' => {
                                       'parent' => 'StandardQuantitationType',
                                       'documentation' => 'A calculated measurement of the intensity of a signal, for example, after a transformation involving normalization and/or replicate DesignElements.  Of type float.',
                                       'attrs' => [],
                                       'associations' => [],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.244',
                                       'package' => 'QuantitationType',
                                       'name' => 'DerivedSignal'
                                     },
                  'BioAssayMap' => {
                                     'parent' => 'Map',
                                     'documentation' => 'The BioAssayMap is the description of how source MeasuredBioAssays and/or DerivedBioAssays are manipulated (mathematically) to produce DerivedBioAssays.',
                                     'attrs' => [],
                                     'associations' => [
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'bioAssayMapTarget',
                                                                        'documentation' => 'The DerivedBioAssay that is produced by the sources of the BioAssayMap.',
                                                                        'class_id' => 'S.90',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'DerivedBioAssay'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'derivedBioAssayMap',
                                                                       'documentation' => 'The DerivedBioAssay that is produced by the sources of the BioAssayMap.',
                                                                       'class_id' => 'S.139',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 3',
                                                                                         'rank' => '3'
                                                                                       },
                                                                       'class_name' => 'BioAssayMap'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'sourceBioAssays',
                                                                        'documentation' => 'The sources of the BioAssayMap that are used to produce a target DerivedBioAssay.',
                                                                        'class_id' => 'S.93',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 2',
                                                                                          'rank' => '2'
                                                                                        },
                                                                        'class_name' => 'BioAssay'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The sources of the BioAssayMap that are used to produce a target DerivedBioAssay.',
                                                                       'class_id' => 'S.139',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioAssayMap'
                                                                     }
                                                         }
                                                       ],
                                     'abstract' => 'false',
                                     'methods' => [],
                                     'id' => 'S.139',
                                     'package' => 'BioAssayData',
                                     'name' => 'BioAssayMap'
                                   },
                  'ZoneLayout' => {
                                    'parent' => 'Extendable',
                                    'documentation' => 'Specifies the layout of features in a rectangular grid.',
                                    'attrs' => [
                                                 {
                                                   'documentation' => 'The number of features from left to right.',
                                                   'id' => 'S.16',
                                                   'type' => 'int',
                                                   'name' => 'numFeaturesPerRow'
                                                 },
                                                 {
                                                   'documentation' => 'The number of features from top to bottom of the grid.',
                                                   'id' => 'S.17',
                                                   'type' => 'int',
                                                   'name' => 'numFeaturesPerCol'
                                                 },
                                                 {
                                                   'documentation' => 'Spacing between the rows.',
                                                   'id' => 'S.18',
                                                   'type' => 'float',
                                                   'name' => 'spacingBetweenRows'
                                                 },
                                                 {
                                                   'documentation' => 'Spacing between the columns.',
                                                   'id' => 'S.19',
                                                   'type' => 'float',
                                                   'name' => 'spacingBetweenCols'
                                                 }
                                               ],
                                    'associations' => [
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'distanceUnit',
                                                                       'documentation' => 'Unit of the ZoneLayout attributes.',
                                                                       'class_id' => 'S.199',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 1',
                                                                                         'rank' => '1'
                                                                                       },
                                                                       'class_name' => 'DistanceUnit'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'Unit of the ZoneLayout attributes.',
                                                                      'class_id' => 'S.15',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'ZoneLayout'
                                                                    }
                                                        }
                                                      ],
                                    'abstract' => 'false',
                                    'methods' => [],
                                    'id' => 'S.15',
                                    'package' => 'ArrayDesign',
                                    'name' => 'ZoneLayout'
                                  },
                  'ReporterGroup' => {
                                       'parent' => 'DesignElementGroup',
                                       'documentation' => 'Allows specification of the type of Reporter Design Element.
',
                                       'attrs' => [],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '1..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'reporters',
                                                                          'documentation' => 'The reporters that belong to this group.',
                                                                          'class_id' => 'S.258',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'Reporter'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The reporters that belong to this group.',
                                                                         'class_id' => 'S.32',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'ReporterGroup'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.32',
                                       'package' => 'ArrayDesign',
                                       'name' => 'ReporterGroup'
                                     },
                  'MassUnit' => {
                                  'parent' => 'Unit',
                                  'documentation' => 'Mass',
                                  'attrs' => [
                                               {
                                                 'id' => 'S.206',
                                                 'type' => 'enum {kg,g,mg,ug,ng,pg,fg,other}',
                                                 'name' => 'unitNameCV'
                                               }
                                             ],
                                  'associations' => [],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.205',
                                  'package' => 'Measurement',
                                  'name' => 'MassUnit'
                                },
                  'ParameterValue' => {
                                        'parent' => 'Extendable',
                                        'documentation' => 'The value of a Parameter.',
                                        'attrs' => [
                                                     {
                                                       'documentation' => 'The value of the parameter.  Will have the datatype of its associated Parameter.',
                                                       'id' => 'S.154',
                                                       'type' => 'any',
                                                       'name' => 'value'
                                                     }
                                                   ],
                                        'associations' => [
                                                            {
                                                              'other' => {
                                                                           'cardinality' => '1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'parameterType',
                                                                           'documentation' => 'The parameter this value is for.',
                                                                           'class_id' => 'S.152',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 1',
                                                                                             'rank' => '1'
                                                                                           },
                                                                           'class_name' => 'Parameter'
                                                                         },
                                                              'self' => {
                                                                          'cardinality' => '0..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => undef,
                                                                          'documentation' => 'The parameter this value is for.',
                                                                          'class_id' => 'S.153',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'false',
                                                                          'constraint' => undef,
                                                                          'class_name' => 'ParameterValue'
                                                                        }
                                                            }
                                                          ],
                                        'abstract' => 'false',
                                        'methods' => [],
                                        'id' => 'S.153',
                                        'package' => 'Protocol',
                                        'name' => 'ParameterValue'
                                      },
                  'FeatureDimension' => {
                                          'parent' => 'DesignElementDimension',
                                          'documentation' => 'Specialized DesignElementDimension to hold Features.',
                                          'attrs' => [],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'containedFeatures',
                                                                             'documentation' => 'The features for this dimension.',
                                                                             'class_id' => 'S.262',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 1,
                                                                                               'constraint' => 'ordered rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'Feature'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '0..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The features for this dimension.',
                                                                            'class_id' => 'S.142',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'FeatureDimension'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.142',
                                          'package' => 'BioAssayData',
                                          'name' => 'FeatureDimension'
                                        },
                  'DistanceUnit' => {
                                      'parent' => 'Unit',
                                      'documentation' => 'Distance',
                                      'attrs' => [
                                                   {
                                                     'id' => 'S.200',
                                                     'type' => 'enum {fm,pm,nm,um,mm,cm,m,other}',
                                                     'name' => 'unitNameCV'
                                                   }
                                                 ],
                                      'associations' => [],
                                      'abstract' => 'false',
                                      'methods' => [],
                                      'id' => 'S.199',
                                      'package' => 'Measurement',
                                      'name' => 'DistanceUnit'
                                    },
                  'ExternalReference' => {
                                           'parent' => 'Extendable',
                                           'documentation' => 'A reference to the originating source for the object.',
                                           'attrs' => [
                                                        {
                                                          'documentation' => 'The originating server for the object, a network address or common name.',
                                                          'id' => 'S.181',
                                                          'type' => 'String',
                                                          'name' => 'exportedFromServer'
                                                        },
                                                        {
                                                          'documentation' => 'Name of the database, if applicable, that the object was exported from.',
                                                          'id' => 'S.182',
                                                          'type' => 'String',
                                                          'name' => 'exportedFromDB'
                                                        },
                                                        {
                                                          'documentation' => 'The identifier of the object at the originating source.',
                                                          'id' => 'S.183',
                                                          'type' => 'String',
                                                          'name' => 'exportID'
                                                        },
                                                        {
                                                          'documentation' => 'The name of the object at the originating source.',
                                                          'id' => 'S.184',
                                                          'type' => 'String',
                                                          'name' => 'exportName'
                                                        }
                                                      ],
                                           'associations' => [],
                                           'abstract' => 'false',
                                           'methods' => [],
                                           'id' => 'S.180',
                                           'package' => 'Description',
                                           'name' => 'ExternalReference'
                                         },
                  'BioAssayCreation' => {
                                          'subclasses' => [
                                                            'Hybridization'
                                                          ],
                                          'parent' => 'BioEvent',
                                          'documentation' => 'The process by which an array and one or more biomaterials are combined to create a bioAssayCreation.',
                                          'attrs' => [],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'array',
                                                                             'documentation' => 'The array used in the BioAssayCreation event.',
                                                                             'class_id' => 'S.40',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 2',
                                                                                               'rank' => '2'
                                                                                             },
                                                                             'class_name' => 'Array'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '0..1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The array used in the BioAssayCreation event.',
                                                                            'class_id' => 'S.96',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'BioAssayCreation'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'sourceBioMaterialMeasurements',
                                                                             'documentation' => 'The BioSample and its amount used in the BioAssayCreation event.',
                                                                             'class_id' => 'S.78',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'BioMaterialMeasurement'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The BioSample and its amount used in the BioAssayCreation event.',
                                                                            'class_id' => 'S.96',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'BioAssayCreation'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'physicalBioAssayTarget',
                                                                             'documentation' => 'The association between the BioAssayCreation event (typically Hybridization) and the PhysicalBioAssay and its annotation of this event.',
                                                                             'class_id' => 'S.89',
                                                                             'aggregation' => 'composite',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 3',
                                                                                               'rank' => '3'
                                                                                             },
                                                                             'class_name' => 'PhysicalBioAssay'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '0..1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'bioAssayCreation',
                                                                            'documentation' => 'The association between the BioAssayCreation event (typically Hybridization) and the PhysicalBioAssay and its annotation of this event.',
                                                                            'class_id' => 'S.96',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 2',
                                                                                              'rank' => '2'
                                                                                            },
                                                                            'class_name' => 'BioAssayCreation'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.96',
                                          'package' => 'BioAssay',
                                          'name' => 'BioAssayCreation'
                                        },
                  'BioAssayMapping' => {
                                         'parent' => 'Extendable',
                                         'documentation' => 'Container of the mappings of the input BioAssay dimensions to the output BioAssay dimension.',
                                         'attrs' => [],
                                         'associations' => [
                                                             {
                                                               'other' => {
                                                                            'cardinality' => '1..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'bioAssayMaps',
                                                                            'documentation' => 'The maps for the BioAssays.',
                                                                            'class_id' => 'S.139',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 1',
                                                                                              'rank' => '1'
                                                                                            },
                                                                            'class_name' => 'BioAssayMap'
                                                                          },
                                                               'self' => {
                                                                           'cardinality' => '0..N',
                                                                           'ordering' => 'unordered',
                                                                           'name' => undef,
                                                                           'documentation' => 'The maps for the BioAssays.',
                                                                           'class_id' => 'S.122',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'false',
                                                                           'constraint' => undef,
                                                                           'class_name' => 'BioAssayMapping'
                                                                         }
                                                             }
                                                           ],
                                         'abstract' => 'false',
                                         'methods' => [],
                                         'id' => 'S.122',
                                         'package' => 'BioAssayData',
                                         'name' => 'BioAssayMapping'
                                       },
                  'BioMaterial' => {
                                     'subclasses' => [
                                                       'BioSource',
                                                       'LabeledExtract',
                                                       'BioSample'
                                                     ],
                                     'parent' => 'Identifiable',
                                     'documentation' => 'BioMaterial is an abstract class that represents the important substances such as cells, tissues, DNA, proteins, etc...  Biomaterials can be related to other biomaterial through a directed acyclic graph (represented by treatment(s)).',
                                     'attrs' => [],
                                     'associations' => [
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'treatments',
                                                                        'documentation' => 'This association is one way from BioMaterial to Treatment.  From this a BioMaterial can discover the amount and type of BioMaterial that was part of the treatment that produced it.',
                                                                        'class_id' => 'S.79',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 4',
                                                                                          'rank' => '4'
                                                                                        },
                                                                        'class_name' => 'Treatment'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'This association is one way from BioMaterial to Treatment.  From this a BioMaterial can discover the amount and type of BioMaterial that was part of the treatment that produced it.',
                                                                       'class_id' => 'S.72',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioMaterial'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'materialType',
                                                                        'documentation' => 'The type of material used, i.e. rna, dna, lipid, phosphoprotein, etc.',
                                                                        'class_id' => 'S.185',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 3',
                                                                                          'rank' => '3'
                                                                                        },
                                                                        'class_name' => 'OntologyEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'The type of material used, i.e. rna, dna, lipid, phosphoprotein, etc.',
                                                                       'class_id' => 'S.72',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioMaterial'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'characteristics',
                                                                        'documentation' => 'Innate properties of the biosource, such as genotype, cultivar, tissue type, cell type, ploidy, etc.',
                                                                        'class_id' => 'S.185',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 2',
                                                                                          'rank' => '2'
                                                                                        },
                                                                        'class_name' => 'OntologyEntry'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Innate properties of the biosource, such as genotype, cultivar, tissue type, cell type, ploidy, etc.',
                                                                       'class_id' => 'S.72',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioMaterial'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'qualityControlStatistics',
                                                                        'documentation' => 'Measures of the quality of the BioMaterial.',
                                                                        'class_id' => 'S.6',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'NameValueType'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Measures of the quality of the BioMaterial.',
                                                                       'class_id' => 'S.72',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'BioMaterial'
                                                                     }
                                                         }
                                                       ],
                                     'abstract' => 'true',
                                     'methods' => [],
                                     'id' => 'S.72',
                                     'package' => 'BioMaterial',
                                     'name' => 'BioMaterial'
                                   },
                  'ImageAcquisition' => {
                                          'parent' => 'BioAssayTreatment',
                                          'documentation' => 'The process by which an image is generated (typically scanning).',
                                          'attrs' => [],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'images',
                                                                             'documentation' => 'The images produced by the ImageAcquisition event.',
                                                                             'class_id' => 'S.91',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'Image'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The images produced by the ImageAcquisition event.',
                                                                            'class_id' => 'S.99',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ImageAcquisition'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.99',
                                          'package' => 'BioAssay',
                                          'name' => 'ImageAcquisition'
                                        },
                  'Ratio' => {
                               'parent' => 'StandardQuantitationType',
                               'documentation' => 'The ratio of two or more signals, typically between two channels.  Of type float.',
                               'attrs' => [],
                               'associations' => [],
                               'abstract' => 'false',
                               'methods' => [],
                               'id' => 'S.249',
                               'package' => 'QuantitationType',
                               'name' => 'Ratio'
                             },
                  'DesignElementMapping' => {
                                              'parent' => 'Extendable',
                                              'documentation' => 'Container of the mappings of the input DesignElement dimensions to the output DesignElement dimension.',
                                              'attrs' => [],
                                              'associations' => [
                                                                  {
                                                                    'other' => {
                                                                                 'cardinality' => '1..N',
                                                                                 'ordering' => 'unordered',
                                                                                 'name' => 'designElementMaps',
                                                                                 'documentation' => 'The maps for the DesignElements.',
                                                                                 'class_id' => 'S.138',
                                                                                 'aggregation' => 'none',
                                                                                 'navigable' => 'true',
                                                                                 'constraint' => {
                                                                                                   'ordered' => 0,
                                                                                                   'constraint' => 'rank: 1',
                                                                                                   'rank' => '1'
                                                                                                 },
                                                                                 'class_name' => 'DesignElementMap'
                                                                               },
                                                                    'self' => {
                                                                                'cardinality' => '0..N',
                                                                                'ordering' => 'unordered',
                                                                                'name' => undef,
                                                                                'documentation' => 'The maps for the DesignElements.',
                                                                                'class_id' => 'S.129',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'false',
                                                                                'constraint' => undef,
                                                                                'class_name' => 'DesignElementMapping'
                                                                              }
                                                                  }
                                                                ],
                                              'abstract' => 'false',
                                              'methods' => [],
                                              'id' => 'S.129',
                                              'package' => 'BioAssayData',
                                              'name' => 'DesignElementMapping'
                                            },
                  'Software' => {
                                  'parent' => 'Parameterizable',
                                  'documentation' => 'Software represents the software used.  Examples of Software include: feature extraction software, clustering software, etc...',
                                  'attrs' => [],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'softwareManufacturers',
                                                                     'documentation' => 'Contact for information on the software.',
                                                                     'class_id' => 'S.112',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 4',
                                                                                       'rank' => '4'
                                                                                     },
                                                                     'class_name' => 'Contact'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Contact for information on the software.',
                                                                    'class_id' => 'S.157',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Software'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'hardware',
                                                                     'documentation' => 'Associates Hardware and Software together.',
                                                                     'class_id' => 'S.158',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 2',
                                                                                       'rank' => '2'
                                                                                     },
                                                                     'class_name' => 'Hardware'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'softwares',
                                                                    'documentation' => 'Associates Hardware and Software together.',
                                                                    'class_id' => 'S.157',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 2',
                                                                                      'rank' => '2'
                                                                                    },
                                                                    'class_name' => 'Software'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'softwares',
                                                                     'documentation' => 'Software packages this software uses, i.e. operating system, 3rd party software packages, etc.',
                                                                     'class_id' => 'S.157',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 3',
                                                                                       'rank' => '3'
                                                                                     },
                                                                     'class_name' => 'Software'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Software packages this software uses, i.e. operating system, 3rd party software packages, etc.',
                                                                    'class_id' => 'S.157',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Software'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'type',
                                                                     'documentation' => 'The type of a piece of Software.  Examples include: feature extractor...',
                                                                     'class_id' => 'S.185',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'OntologyEntry'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The type of a piece of Software.  Examples include: feature extractor...',
                                                                    'class_id' => 'S.157',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Software'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.157',
                                  'package' => 'Protocol',
                                  'name' => 'Software'
                                },
                  'MeasuredSignal' => {
                                        'parent' => 'StandardQuantitationType',
                                        'documentation' => 'Best measure from feature extraction as to the presence and intensity of the signal.  Of type float.',
                                        'attrs' => [],
                                        'associations' => [],
                                        'abstract' => 'false',
                                        'methods' => [],
                                        'id' => 'S.245',
                                        'package' => 'QuantitationType',
                                        'name' => 'MeasuredSignal'
                                      },
                  'HardwareApplication' => {
                                             'parent' => 'ParameterizableApplication',
                                             'documentation' => 'The use of a piece of hardware with the requisite Parameters and ParameterValues.',
                                             'attrs' => [
                                                          {
                                                            'documentation' => 'Manufacturer\'s identifier for the Hardware.',
                                                            'id' => 'S.162',
                                                            'type' => 'String',
                                                            'name' => 'serialNumber'
                                                          }
                                                        ],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'hardware',
                                                                                'documentation' => 'The underlying hardware.',
                                                                                'class_id' => 'S.158',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'Hardware'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The underlying hardware.',
                                                                               'class_id' => 'S.161',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'HardwareApplication'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.161',
                                             'package' => 'Protocol',
                                             'name' => 'HardwareApplication'
                                           },
                  'ZoneDefect' => {
                                    'parent' => 'Extendable',
                                    'documentation' => 'Stores the defect information for a zone.',
                                    'attrs' => [],
                                    'associations' => [
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'zone',
                                                                       'documentation' => 'Reference to the Zone that was misprinted.',
                                                                       'class_id' => 'S.25',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 3',
                                                                                         'rank' => '3'
                                                                                       },
                                                                       'class_name' => 'Zone'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'Reference to the Zone that was misprinted.',
                                                                      'class_id' => 'S.69',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'ZoneDefect'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'positionDelta',
                                                                       'documentation' => 'How the zone deviates in position from the ArrayDesign.',
                                                                       'class_id' => 'S.66',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 2',
                                                                                         'rank' => '2'
                                                                                       },
                                                                       'class_name' => 'PositionDelta'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'How the zone deviates in position from the ArrayDesign.',
                                                                      'class_id' => 'S.69',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'ZoneDefect'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'defectType',
                                                                       'documentation' => 'Indicates the type of defect (e.g. a missing zone or a moved zone).',
                                                                       'class_id' => 'S.185',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 1',
                                                                                         'rank' => '1'
                                                                                       },
                                                                       'class_name' => 'OntologyEntry'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'Indicates the type of defect (e.g. a missing zone or a moved zone).',
                                                                      'class_id' => 'S.69',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'ZoneDefect'
                                                                    }
                                                        }
                                                      ],
                                    'abstract' => 'false',
                                    'methods' => [],
                                    'id' => 'S.69',
                                    'package' => 'Array',
                                    'name' => 'ZoneDefect'
                                  },
                  'SecurityGroup' => {
                                       'parent' => 'Identifiable',
                                       'documentation' => 'Groups contacts together based on their security privileges.',
                                       'attrs' => [],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '1..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'members',
                                                                          'documentation' => 'The members of the Security Group.',
                                                                          'class_id' => 'S.112',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'Contact'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The members of the Security Group.',
                                                                         'class_id' => 'S.111',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'SecurityGroup'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.111',
                                       'package' => 'AuditAndSecurity',
                                       'name' => 'SecurityGroup'
                                     },
                  'CompositeSequence' => {
                                           'parent' => 'DesignElement',
                                           'documentation' => 'A collection of Reporter or CompositeSequence Design Elements, annotated through the association to BioSequence. 
',
                                           'attrs' => [],
                                           'associations' => [
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '0..N',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'biologicalCharacteristics',
                                                                              'documentation' => 'The annotation on the BioSequence this CompositeSequence represents.  Typically the sequences will be a Genes, Exons, or SpliceVariants.',
                                                                              'class_id' => 'S.231',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 1',
                                                                                                'rank' => '1'
                                                                                              },
                                                                              'class_name' => 'BioSequence'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => undef,
                                                                             'documentation' => 'The annotation on the BioSequence this CompositeSequence represents.  Typically the sequences will be a Genes, Exons, or SpliceVariants.',
                                                                             'class_id' => 'S.261',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'false',
                                                                             'constraint' => undef,
                                                                             'class_name' => 'CompositeSequence'
                                                                           }
                                                               },
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '0..N',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'reporterCompositeMaps',
                                                                              'documentation' => 'A map to the reporters that compose this CompositeSequence.',
                                                                              'class_id' => 'S.270',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 2',
                                                                                                'rank' => '2'
                                                                                              },
                                                                              'class_name' => 'ReporterCompositeMap'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'compositeSequence',
                                                                             'documentation' => 'A map to the reporters that compose this CompositeSequence.',
                                                                             'class_id' => 'S.261',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'CompositeSequence'
                                                                           }
                                                               },
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '0..N',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'compositeCompositeMaps',
                                                                              'documentation' => 'A map to the compositeSequences that compose this CompositeSequence.',
                                                                              'class_id' => 'S.268',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 2',
                                                                                                'rank' => '2'
                                                                                              },
                                                                              'class_name' => 'CompositeCompositeMap'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'compositeSequence',
                                                                             'documentation' => 'A map to the compositeSequences that compose this CompositeSequence.',
                                                                             'class_id' => 'S.261',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'CompositeSequence'
                                                                           }
                                                               }
                                                             ],
                                           'abstract' => 'false',
                                           'methods' => [],
                                           'id' => 'S.261',
                                           'package' => 'DesignElement',
                                           'name' => 'CompositeSequence'
                                         },
                  'LabeledExtract' => {
                                        'parent' => 'BioMaterial',
                                        'documentation' => 'LabeledExtracts are special BioSamples that have Compounds which are detectable (these are often fluorescent or reactive moieties).',
                                        'attrs' => [],
                                        'associations' => [
                                                            {
                                                              'other' => {
                                                                           'cardinality' => '1..N',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'labels',
                                                                           'documentation' => 'Compound used to label the extract.',
                                                                           'class_id' => 'S.75',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 1',
                                                                                             'rank' => '1'
                                                                                           },
                                                                           'class_name' => 'Compound'
                                                                         },
                                                              'self' => {
                                                                          'cardinality' => '0..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => undef,
                                                                          'documentation' => 'Compound used to label the extract.',
                                                                          'class_id' => 'S.73',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'false',
                                                                          'constraint' => undef,
                                                                          'class_name' => 'LabeledExtract'
                                                                        }
                                                            }
                                                          ],
                                        'abstract' => 'false',
                                        'methods' => [],
                                        'id' => 'S.73',
                                        'package' => 'BioMaterial',
                                        'name' => 'LabeledExtract'
                                      },
                  'DesignElementMap' => {
                                          'subclasses' => [
                                                            'CompositeCompositeMap',
                                                            'FeatureReporterMap',
                                                            'ReporterCompositeMap'
                                                          ],
                                          'parent' => 'Map',
                                          'documentation' => 'A DesignElementMap is the description of how source DesignElements are transformed into a target DesignElement.',
                                          'attrs' => [],
                                          'associations' => [],
                                          'abstract' => 'true',
                                          'methods' => [],
                                          'id' => 'S.138',
                                          'package' => 'BioAssayData',
                                          'name' => 'DesignElementMap'
                                        },
                  'FeatureGroup' => {
                                      'parent' => 'DesignElementGroup',
                                      'documentation' => 'A collection of like features.',
                                      'attrs' => [
                                                   {
                                                     'documentation' => 'The width of the feature.',
                                                     'id' => 'S.34',
                                                     'type' => 'float',
                                                     'name' => 'featureWidth'
                                                   },
                                                   {
                                                     'documentation' => 'The length of the feature.',
                                                     'id' => 'S.35',
                                                     'type' => 'float',
                                                     'name' => 'featureLength'
                                                   },
                                                   {
                                                     'documentation' => 'The height of the feature.',
                                                     'id' => 'S.36',
                                                     'type' => 'float',
                                                     'name' => 'featureHeight'
                                                   }
                                                 ],
                                      'associations' => [
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'distanceUnit',
                                                                         'documentation' => 'The unit for the feature measures.',
                                                                         'class_id' => 'S.199',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 3',
                                                                                           'rank' => '3'
                                                                                         },
                                                                         'class_name' => 'DistanceUnit'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The unit for the feature measures.',
                                                                        'class_id' => 'S.33',
                                                                        'aggregation' => 'composite',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'FeatureGroup'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '1..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'features',
                                                                         'documentation' => 'The features that belong to this group.',
                                                                         'class_id' => 'S.262',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 4',
                                                                                           'rank' => '4'
                                                                                         },
                                                                         'class_name' => 'Feature'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'featureGroup',
                                                                        'documentation' => 'The features that belong to this group.',
                                                                        'class_id' => 'S.33',
                                                                        'aggregation' => 'composite',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 6',
                                                                                          'rank' => '6'
                                                                                        },
                                                                        'class_name' => 'FeatureGroup'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'technologyType',
                                                                         'documentation' => 'The technology type of this design.  By specifying a technology type, higher level analysis can use appropriate algorithms to compare the results from multiple arrays.  The technology type may be spotted cDNA or in situ photolithography.',
                                                                         'class_id' => 'S.185',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 1',
                                                                                           'rank' => '1'
                                                                                         },
                                                                         'class_name' => 'OntologyEntry'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The technology type of this design.  By specifying a technology type, higher level analysis can use appropriate algorithms to compare the results from multiple arrays.  The technology type may be spotted cDNA or in situ photolithography.',
                                                                        'class_id' => 'S.33',
                                                                        'aggregation' => 'composite',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'FeatureGroup'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'featureShape',
                                                                         'documentation' => 'The expected shape of the feature on the array: circular, oval, square, etc.',
                                                                         'class_id' => 'S.185',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 2',
                                                                                           'rank' => '2'
                                                                                         },
                                                                         'class_name' => 'OntologyEntry'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The expected shape of the feature on the array: circular, oval, square, etc.',
                                                                        'class_id' => 'S.33',
                                                                        'aggregation' => 'composite',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'FeatureGroup'
                                                                      }
                                                          }
                                                        ],
                                      'abstract' => 'false',
                                      'methods' => [],
                                      'id' => 'S.33',
                                      'package' => 'ArrayDesign',
                                      'name' => 'FeatureGroup'
                                    },
                  'BioAssay' => {
                                  'subclasses' => [
                                                    'PhysicalBioAssay',
                                                    'DerivedBioAssay',
                                                    'MeasuredBioAssay'
                                                  ],
                                  'parent' => 'Identifiable',
                                  'documentation' => 'An abstract class which represents both physical and computational groupings of arrays and biomaterials.
',
                                  'attrs' => [],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'channels',
                                                                     'documentation' => 'Channels can be non-null for all subclasses.  For instance, collapsing across replicate features will create a DerivedBioAssay that will potentially reference channels.',
                                                                     'class_id' => 'S.94',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'Channel'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'Channels can be non-null for all subclasses.  For instance, collapsing across replicate features will create a DerivedBioAssay that will potentially reference channels.',
                                                                    'class_id' => 'S.93',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'BioAssay'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..N',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'bioAssayFactorValues',
                                                                     'documentation' => 'The values that this BioAssay is associated with for the experiment.',
                                                                     'class_id' => 'S.147',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 2',
                                                                                       'rank' => '2'
                                                                                     },
                                                                     'class_name' => 'FactorValue'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The values that this BioAssay is associated with for the experiment.',
                                                                    'class_id' => 'S.93',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'BioAssay'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'true',
                                  'methods' => [],
                                  'id' => 'S.93',
                                  'package' => 'BioAssay',
                                  'name' => 'BioAssay'
                                },
                  'Image' => {
                               'parent' => 'Identifiable',
                               'documentation' => 'An image is created by an imageAcquisition event, typically by scanning the hybridized array (the PhysicalBioAssay).
',
                               'attrs' => [
                                            {
                                              'documentation' => 'The file location in which an image may be found.',
                                              'id' => 'S.92',
                                              'type' => 'String',
                                              'name' => 'URI'
                                            }
                                          ],
                               'associations' => [
                                                   {
                                                     'other' => {
                                                                  'cardinality' => '0..N',
                                                                  'ordering' => 'unordered',
                                                                  'name' => 'channels',
                                                                  'documentation' => 'The channels captured in this image.',
                                                                  'class_id' => 'S.94',
                                                                  'aggregation' => 'none',
                                                                  'navigable' => 'true',
                                                                  'constraint' => {
                                                                                    'ordered' => 0,
                                                                                    'constraint' => 'rank: 1',
                                                                                    'rank' => '1'
                                                                                  },
                                                                  'class_name' => 'Channel'
                                                                },
                                                     'self' => {
                                                                 'cardinality' => '1',
                                                                 'ordering' => 'unordered',
                                                                 'name' => undef,
                                                                 'documentation' => 'The channels captured in this image.',
                                                                 'class_id' => 'S.91',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'false',
                                                                 'constraint' => undef,
                                                                 'class_name' => 'Image'
                                                               }
                                                   },
                                                   {
                                                     'other' => {
                                                                  'cardinality' => '1',
                                                                  'ordering' => 'unordered',
                                                                  'name' => 'format',
                                                                  'documentation' => 'The file format of the image typically a TIF or a JPEG.',
                                                                  'class_id' => 'S.185',
                                                                  'aggregation' => 'none',
                                                                  'navigable' => 'true',
                                                                  'constraint' => {
                                                                                    'ordered' => 0,
                                                                                    'constraint' => 'rank: 2',
                                                                                    'rank' => '2'
                                                                                  },
                                                                  'class_name' => 'OntologyEntry'
                                                                },
                                                     'self' => {
                                                                 'cardinality' => '1',
                                                                 'ordering' => 'unordered',
                                                                 'name' => undef,
                                                                 'documentation' => 'The file format of the image typically a TIF or a JPEG.',
                                                                 'class_id' => 'S.91',
                                                                 'aggregation' => 'composite',
                                                                 'navigable' => 'false',
                                                                 'constraint' => undef,
                                                                 'class_name' => 'Image'
                                                               }
                                                   }
                                                 ],
                               'abstract' => 'false',
                               'methods' => [],
                               'id' => 'S.91',
                               'package' => 'BioAssay',
                               'name' => 'Image'
                             },
                  'PositionDelta' => {
                                       'parent' => 'Extendable',
                                       'documentation' => 'The delta the feature was actually printed on the array from the position specified for the feature in the array design.',
                                       'attrs' => [
                                                    {
                                                      'documentation' => 'Deviation from the y coordinate of this feature\'s position.',
                                                      'id' => 'S.67',
                                                      'type' => 'float',
                                                      'name' => 'deltaX'
                                                    },
                                                    {
                                                      'documentation' => 'Deviation from the y coordinate of this feature\'s position.',
                                                      'id' => 'S.68',
                                                      'type' => 'float',
                                                      'name' => 'deltaY'
                                                    }
                                                  ],
                                       'associations' => [
                                                           {
                                                             'other' => {
                                                                          'cardinality' => '0..1',
                                                                          'ordering' => 'unordered',
                                                                          'name' => 'distanceUnit',
                                                                          'documentation' => 'The unit for the attributes.',
                                                                          'class_id' => 'S.199',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'true',
                                                                          'constraint' => {
                                                                                            'ordered' => 0,
                                                                                            'constraint' => 'rank: 1',
                                                                                            'rank' => '1'
                                                                                          },
                                                                          'class_name' => 'DistanceUnit'
                                                                        },
                                                             'self' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => undef,
                                                                         'documentation' => 'The unit for the attributes.',
                                                                         'class_id' => 'S.66',
                                                                         'aggregation' => 'composite',
                                                                         'navigable' => 'false',
                                                                         'constraint' => undef,
                                                                         'class_name' => 'PositionDelta'
                                                                       }
                                                           }
                                                         ],
                                       'abstract' => 'false',
                                       'methods' => [],
                                       'id' => 'S.66',
                                       'package' => 'Array',
                                       'name' => 'PositionDelta'
                                     },
                  'Describable' => {
                                     'subclasses' => [
                                                       'Node',
                                                       'NodeContents',
                                                       'Description',
                                                       'Audit',
                                                       'Identifiable',
                                                       'Fiducial',
                                                       'BibliographicReference',
                                                       'ExperimentDesign',
                                                       'ManufactureLIMS',
                                                       'SeqFeature',
                                                       'ParameterizableApplication'
                                                     ],
                                     'parent' => 'Extendable',
                                     'documentation' => 'Abstract class that allows subclasses to inherit the association to Description, for detailed annotations such as Ontology entries and Database references, the association to Audit, for tracking changes, and the association to Security for indicating permissions.',
                                     'attrs' => [],
                                     'associations' => [
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'security',
                                                                        'documentation' => 'Information on the security for the instance of the class.',
                                                                        'class_id' => 'S.106',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 3',
                                                                                          'rank' => '3'
                                                                                        },
                                                                        'class_name' => 'Security'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Information on the security for the instance of the class.',
                                                                       'class_id' => 'S.1',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'Describable'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'auditTrail',
                                                                        'documentation' => 'A list of Audit instances that track changes to the instance of Describable.',
                                                                        'class_id' => 'S.107',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 2',
                                                                                          'rank' => '2'
                                                                                        },
                                                                        'class_name' => 'Audit'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'A list of Audit instances that track changes to the instance of Describable.',
                                                                       'class_id' => 'S.1',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'Describable'
                                                                     }
                                                         },
                                                         {
                                                           'other' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => 'descriptions',
                                                                        'documentation' => 'Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.',
                                                                        'class_id' => 'S.170',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'true',
                                                                        'constraint' => {
                                                                                          'ordered' => 0,
                                                                                          'constraint' => 'rank: 1',
                                                                                          'rank' => '1'
                                                                                        },
                                                                        'class_name' => 'Description'
                                                                      },
                                                           'self' => {
                                                                       'cardinality' => '1',
                                                                       'ordering' => 'unordered',
                                                                       'name' => undef,
                                                                       'documentation' => 'Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.',
                                                                       'class_id' => 'S.1',
                                                                       'aggregation' => 'composite',
                                                                       'navigable' => 'false',
                                                                       'constraint' => undef,
                                                                       'class_name' => 'Describable'
                                                                     }
                                                         }
                                                       ],
                                     'abstract' => 'true',
                                     'methods' => [],
                                     'id' => 'S.1',
                                     'package' => 'MAGE',
                                     'name' => 'Describable'
                                   },
                  'CompositeGroup' => {
                                        'parent' => 'DesignElementGroup',
                                        'documentation' => 'Allows specification of the type of Composite Design Element.',
                                        'attrs' => [],
                                        'associations' => [
                                                            {
                                                              'other' => {
                                                                           'cardinality' => '1..N',
                                                                           'ordering' => 'unordered',
                                                                           'name' => 'compositeSequences',
                                                                           'documentation' => 'The compositeSequences that belong to this group.',
                                                                           'class_id' => 'S.261',
                                                                           'aggregation' => 'none',
                                                                           'navigable' => 'true',
                                                                           'constraint' => {
                                                                                             'ordered' => 0,
                                                                                             'constraint' => 'rank: 1',
                                                                                             'rank' => '1'
                                                                                           },
                                                                           'class_name' => 'CompositeSequence'
                                                                         },
                                                              'self' => {
                                                                          'cardinality' => '0..N',
                                                                          'ordering' => 'unordered',
                                                                          'name' => undef,
                                                                          'documentation' => 'The compositeSequences that belong to this group.',
                                                                          'class_id' => 'S.38',
                                                                          'aggregation' => 'none',
                                                                          'navigable' => 'false',
                                                                          'constraint' => undef,
                                                                          'class_name' => 'CompositeGroup'
                                                                        }
                                                            }
                                                          ],
                                        'abstract' => 'false',
                                        'methods' => [],
                                        'id' => 'S.38',
                                        'package' => 'ArrayDesign',
                                        'name' => 'CompositeGroup'
                                      },
                  'BibliographicReference' => {
                                                'parent' => 'Describable',
                                                'documentation' => 'Attributes for the most common criteria and association with OntologyEntry allows criteria to be specified for searching for a Bibliographic reference.
',
                                                'attrs' => [
                                                             {
                                                               'id' => 'S.216',
                                                               'type' => 'String',
                                                               'name' => 'title'
                                                             },
                                                             {
                                                               'id' => 'S.217',
                                                               'type' => 'String',
                                                               'name' => 'authors'
                                                             },
                                                             {
                                                               'id' => 'S.218',
                                                               'type' => 'String',
                                                               'name' => 'publication'
                                                             },
                                                             {
                                                               'id' => 'S.219',
                                                               'type' => 'String',
                                                               'name' => 'publisher'
                                                             },
                                                             {
                                                               'id' => 'S.220',
                                                               'type' => 'String',
                                                               'name' => 'editor'
                                                             },
                                                             {
                                                               'id' => 'S.221',
                                                               'type' => 'Date',
                                                               'name' => 'year'
                                                             },
                                                             {
                                                               'id' => 'S.222',
                                                               'type' => 'String',
                                                               'name' => 'volume'
                                                             },
                                                             {
                                                               'id' => 'S.223',
                                                               'type' => 'String',
                                                               'name' => 'issue'
                                                             },
                                                             {
                                                               'id' => 'S.224',
                                                               'type' => 'String',
                                                               'name' => 'pages'
                                                             },
                                                             {
                                                               'id' => 'S.225',
                                                               'type' => 'String',
                                                               'name' => 'URI'
                                                             }
                                                           ],
                                                'associations' => [
                                                                    {
                                                                      'other' => {
                                                                                   'cardinality' => '0..N',
                                                                                   'ordering' => 'unordered',
                                                                                   'name' => 'accessions',
                                                                                   'documentation' => 'References in publications, eg Medline and PubMed, for this BibliographicReference.',
                                                                                   'class_id' => 'S.173',
                                                                                   'aggregation' => 'none',
                                                                                   'navigable' => 'true',
                                                                                   'constraint' => {
                                                                                                     'ordered' => 0,
                                                                                                     'constraint' => 'rank: 2',
                                                                                                     'rank' => '2'
                                                                                                   },
                                                                                   'class_name' => 'DatabaseEntry'
                                                                                 },
                                                                      'self' => {
                                                                                  'cardinality' => '1',
                                                                                  'ordering' => 'unordered',
                                                                                  'name' => undef,
                                                                                  'documentation' => 'References in publications, eg Medline and PubMed, for this BibliographicReference.',
                                                                                  'class_id' => 'S.215',
                                                                                  'aggregation' => 'composite',
                                                                                  'navigable' => 'false',
                                                                                  'constraint' => undef,
                                                                                  'class_name' => 'BibliographicReference'
                                                                                }
                                                                    },
                                                                    {
                                                                      'other' => {
                                                                                   'cardinality' => '1..N',
                                                                                   'ordering' => 'unordered',
                                                                                   'name' => 'parameters',
                                                                                   'documentation' => 'Criteria that can be used to look up the reference in a repository.',
                                                                                   'class_id' => 'S.185',
                                                                                   'aggregation' => 'none',
                                                                                   'navigable' => 'true',
                                                                                   'constraint' => {
                                                                                                     'ordered' => 0,
                                                                                                     'constraint' => 'rank: 1',
                                                                                                     'rank' => '1'
                                                                                                   },
                                                                                   'class_name' => 'OntologyEntry'
                                                                                 },
                                                                      'self' => {
                                                                                  'cardinality' => '1',
                                                                                  'ordering' => 'unordered',
                                                                                  'name' => undef,
                                                                                  'documentation' => 'Criteria that can be used to look up the reference in a repository.',
                                                                                  'class_id' => 'S.215',
                                                                                  'aggregation' => 'composite',
                                                                                  'navigable' => 'false',
                                                                                  'constraint' => undef,
                                                                                  'class_name' => 'BibliographicReference'
                                                                                }
                                                                    }
                                                                  ],
                                                'abstract' => 'false',
                                                'methods' => [],
                                                'id' => 'S.215',
                                                'package' => 'BQS',
                                                'name' => 'BibliographicReference'
                                              },
                  'BioSample' => {
                                   'parent' => 'BioMaterial',
                                   'documentation' => 'BioSamples are products of treatments that are of interest.  BioSamples are often used as the sources for other biosamples.  The Type attribute describes the role the BioSample holds in the treatment hierarchy.  This type can be an extract.',
                                   'attrs' => [],
                                   'associations' => [
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'type',
                                                                      'documentation' => 'The Type attribute describes the role the BioSample holds in the treatment hierarchy.  This type can be an extract.',
                                                                      'class_id' => 'S.185',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 1',
                                                                                        'rank' => '1'
                                                                                      },
                                                                      'class_name' => 'OntologyEntry'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The Type attribute describes the role the BioSample holds in the treatment hierarchy.  This type can be an extract.',
                                                                     'class_id' => 'S.74',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'BioSample'
                                                                   }
                                                       }
                                                     ],
                                   'abstract' => 'false',
                                   'methods' => [],
                                   'id' => 'S.74',
                                   'package' => 'BioMaterial',
                                   'name' => 'BioSample'
                                 },
                  'Organization' => {
                                      'parent' => 'Contact',
                                      'documentation' => 'Organizations are entities like companies, universities, government agencies for which the attributes are self describing.',
                                      'attrs' => [],
                                      'associations' => [
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'parent',
                                                                         'documentation' => 'The containing organization (the university or business which a lab belongs to, etc.)',
                                                                         'class_id' => 'S.110',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 1',
                                                                                           'rank' => '1'
                                                                                         },
                                                                         'class_name' => 'Organization'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '0..N',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The containing organization (the university or business which a lab belongs to, etc.)',
                                                                        'class_id' => 'S.110',
                                                                        'aggregation' => 'none',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'Organization'
                                                                      }
                                                          }
                                                        ],
                                      'abstract' => 'false',
                                      'methods' => [],
                                      'id' => 'S.110',
                                      'package' => 'AuditAndSecurity',
                                      'name' => 'Organization'
                                    },
                  'Experiment' => {
                                    'parent' => 'Identifiable',
                                    'documentation' => 'The Experiment is the collection of all the BioAssays that are related by the ExperimentDesign.',
                                    'attrs' => [],
                                    'associations' => [
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'analysisResults',
                                                                       'documentation' => 'The results of analyzing the data, typically with a clustering algorithm.',
                                                                       'class_id' => 'S.82',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 2',
                                                                                         'rank' => '2'
                                                                                       },
                                                                       'class_name' => 'BioAssayDataCluster'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'The results of analyzing the data, typically with a clustering algorithm.',
                                                                      'class_id' => 'S.144',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'Experiment'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'bioAssays',
                                                                       'documentation' => 'The collection of BioAssays for this Experiment.',
                                                                       'class_id' => 'S.93',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 4',
                                                                                         'rank' => '4'
                                                                                       },
                                                                       'class_name' => 'BioAssay'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'The collection of BioAssays for this Experiment.',
                                                                      'class_id' => 'S.144',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'Experiment'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'providers',
                                                                       'documentation' => 'The providers of the Experiment, its data and annotation.',
                                                                       'class_id' => 'S.112',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 1',
                                                                                         'rank' => '1'
                                                                                       },
                                                                       'class_name' => 'Contact'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'The providers of the Experiment, its data and annotation.',
                                                                      'class_id' => 'S.144',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'Experiment'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '0..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'bioAssayData',
                                                                       'documentation' => 'The collection of BioAssayDatas for this Experiment.',
                                                                       'class_id' => 'S.120',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 3',
                                                                                         'rank' => '3'
                                                                                       },
                                                                       'class_name' => 'BioAssayData'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '0..N',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'The collection of BioAssayDatas for this Experiment.',
                                                                      'class_id' => 'S.144',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'Experiment'
                                                                    }
                                                        },
                                                        {
                                                          'other' => {
                                                                       'cardinality' => '1..N',
                                                                       'ordering' => 'unordered',
                                                                       'name' => 'experimentDesigns',
                                                                       'documentation' => 'The association to the description and annotation of the Experiment, along with the grouping of the top-level BioAssays.',
                                                                       'class_id' => 'S.145',
                                                                       'aggregation' => 'none',
                                                                       'navigable' => 'true',
                                                                       'constraint' => {
                                                                                         'ordered' => 0,
                                                                                         'constraint' => 'rank: 5',
                                                                                         'rank' => '5'
                                                                                       },
                                                                       'class_name' => 'ExperimentDesign'
                                                                     },
                                                          'self' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => undef,
                                                                      'documentation' => 'The association to the description and annotation of the Experiment, along with the grouping of the top-level BioAssays.',
                                                                      'class_id' => 'S.144',
                                                                      'aggregation' => 'composite',
                                                                      'navigable' => 'false',
                                                                      'constraint' => undef,
                                                                      'class_name' => 'Experiment'
                                                                    }
                                                        }
                                                      ],
                                    'abstract' => 'false',
                                    'methods' => [],
                                    'id' => 'S.144',
                                    'package' => 'Experiment',
                                    'name' => 'Experiment'
                                  },
                  'BioAssayData' => {
                                      'subclasses' => [
                                                        'DerivedBioAssayData',
                                                        'MeasuredBioAssayData'
                                                      ],
                                      'parent' => 'Identifiable',
                                      'documentation' => 'Represents the dataset created when the BioAssays are created.  BioAssayData is the entry point to the values.  Because the actual values are represented by a different object, BioDataValues, which can be memory intensive, the annotation of the transformation can be gotten separate from the data.',
                                      'attrs' => [],
                                      'associations' => [
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'bioAssayDimension',
                                                                         'documentation' => 'The BioAssays of the BioAssayData.',
                                                                         'class_id' => 'S.135',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 2',
                                                                                           'rank' => '2'
                                                                                         },
                                                                         'class_name' => 'BioAssayDimension'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The BioAssays of the BioAssayData.',
                                                                        'class_id' => 'S.120',
                                                                        'aggregation' => 'aggregate',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'BioAssayData'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'designElementDimension',
                                                                         'documentation' => 'The DesignElements of the BioAssayData.',
                                                                         'class_id' => 'S.123',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 3',
                                                                                           'rank' => '3'
                                                                                         },
                                                                         'class_name' => 'DesignElementDimension'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The DesignElements of the BioAssayData.',
                                                                        'class_id' => 'S.120',
                                                                        'aggregation' => 'aggregate',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'BioAssayData'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'quantitationTypeDimension',
                                                                         'documentation' => 'The QuantitationTypes of the BioAssayData.',
                                                                         'class_id' => 'S.121',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 4',
                                                                                           'rank' => '4'
                                                                                         },
                                                                         'class_name' => 'QuantitationTypeDimension'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The QuantitationTypes of the BioAssayData.',
                                                                        'class_id' => 'S.120',
                                                                        'aggregation' => 'aggregate',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'BioAssayData'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..N',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'summaryStatistics',
                                                                         'documentation' => 'Statistics on the Quality of the BioAssayData.',
                                                                         'class_id' => 'S.6',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 1',
                                                                                           'rank' => '1'
                                                                                         },
                                                                         'class_name' => 'NameValueType'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'Statistics on the Quality of the BioAssayData.',
                                                                        'class_id' => 'S.120',
                                                                        'aggregation' => 'composite',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'BioAssayData'
                                                                      }
                                                          },
                                                          {
                                                            'other' => {
                                                                         'cardinality' => '0..1',
                                                                         'ordering' => 'unordered',
                                                                         'name' => 'bioDataValues',
                                                                         'documentation' => 'The data values of the BioAssayData.',
                                                                         'class_id' => 'S.133',
                                                                         'aggregation' => 'none',
                                                                         'navigable' => 'true',
                                                                         'constraint' => {
                                                                                           'ordered' => 0,
                                                                                           'constraint' => 'rank: 5',
                                                                                           'rank' => '5'
                                                                                         },
                                                                         'class_name' => 'BioDataValues'
                                                                       },
                                                            'self' => {
                                                                        'cardinality' => '1',
                                                                        'ordering' => 'unordered',
                                                                        'name' => undef,
                                                                        'documentation' => 'The data values of the BioAssayData.',
                                                                        'class_id' => 'S.120',
                                                                        'aggregation' => 'composite',
                                                                        'navigable' => 'false',
                                                                        'constraint' => undef,
                                                                        'class_name' => 'BioAssayData'
                                                                      }
                                                          }
                                                        ],
                                      'abstract' => 'true',
                                      'methods' => [],
                                      'id' => 'S.120',
                                      'package' => 'BioAssayData',
                                      'name' => 'BioAssayData'
                                    },
                  'QuantityUnit' => {
                                      'parent' => 'Unit',
                                      'documentation' => 'Quantity',
                                      'attrs' => [
                                                   {
                                                     'id' => 'S.204',
                                                     'type' => 'enum {mol,amol,fmol,pmol,nmol,umol,mmol,molecules,other}',
                                                     'name' => 'unitNameCV'
                                                   }
                                                 ],
                                      'associations' => [],
                                      'abstract' => 'false',
                                      'methods' => [],
                                      'id' => 'S.203',
                                      'package' => 'Measurement',
                                      'name' => 'QuantityUnit'
                                    },
                  'ArrayManufacture' => {
                                          'parent' => 'Identifiable',
                                          'documentation' => 'Describes the process by which arrays are produced.  ',
                                          'attrs' => [
                                                       {
                                                         'documentation' => 'The date the arrays were manufactured',
                                                         'id' => 'S.56',
                                                         'type' => 'String',
                                                         'name' => 'manufacturingDate'
                                                       },
                                                       {
                                                         'documentation' => 'The allowable error of a feature printed to its intended position.',
                                                         'id' => 'S.57',
                                                         'type' => 'float',
                                                         'name' => 'tolerance'
                                                       }
                                                     ],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '1..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'arrays',
                                                                             'documentation' => 'Association between the manufactured array and the information on that manufacture.',
                                                                             'class_id' => 'S.40',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'Array'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'information',
                                                                            'documentation' => 'Association between the manufactured array and the information on that manufacture.',
                                                                            'class_id' => 'S.55',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 2',
                                                                                              'rank' => '2'
                                                                                            },
                                                                            'class_name' => 'ArrayManufacture'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'protocolApplications',
                                                                             'documentation' => 'The protocols followed in the manufacturing of the arrays.',
                                                                             'class_id' => 'S.155',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 5',
                                                                                               'rank' => '5'
                                                                                             },
                                                                             'class_name' => 'ProtocolApplication'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The protocols followed in the manufacturing of the arrays.',
                                                                            'class_id' => 'S.55',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ArrayManufacture'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'featureLIMSs',
                                                                             'documentation' => 'Information on the manufacture of the features.',
                                                                             'class_id' => 'S.60',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 4',
                                                                                               'rank' => '4'
                                                                                             },
                                                                             'class_name' => 'ManufactureLIMS'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'Information on the manufacture of the features.',
                                                                            'class_id' => 'S.55',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ArrayManufacture'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'arrayManufacturers',
                                                                             'documentation' => 'The person or organization to contact for information concerning the ArrayManufacture.',
                                                                             'class_id' => 'S.112',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 2',
                                                                                               'rank' => '2'
                                                                                             },
                                                                             'class_name' => 'Contact'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '0..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The person or organization to contact for information concerning the ArrayManufacture.',
                                                                            'class_id' => 'S.55',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ArrayManufacture'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'qualityControlStatistics',
                                                                             'documentation' => 'Information on the quality of the ArrayManufacture.',
                                                                             'class_id' => 'S.6',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 3',
                                                                                               'rank' => '3'
                                                                                             },
                                                                             'class_name' => 'NameValueType'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'Information on the quality of the ArrayManufacture.',
                                                                            'class_id' => 'S.55',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'ArrayManufacture'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.55',
                                          'package' => 'Array',
                                          'name' => 'ArrayManufacture'
                                        },
                  'ReporterDimension' => {
                                           'parent' => 'DesignElementDimension',
                                           'documentation' => 'Specialized DesignElementDimension to hold Reporters.',
                                           'attrs' => [],
                                           'associations' => [
                                                               {
                                                                 'other' => {
                                                                              'cardinality' => '0..N',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'reporters',
                                                                              'documentation' => 'The reporters for this dimension.',
                                                                              'class_id' => 'S.258',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 1,
                                                                                                'constraint' => 'ordered rank: 1',
                                                                                                'rank' => '1'
                                                                                              },
                                                                              'class_name' => 'Reporter'
                                                                            },
                                                                 'self' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => undef,
                                                                             'documentation' => 'The reporters for this dimension.',
                                                                             'class_id' => 'S.141',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'false',
                                                                             'constraint' => undef,
                                                                             'class_name' => 'ReporterDimension'
                                                                           }
                                                               }
                                                             ],
                                           'abstract' => 'false',
                                           'methods' => [],
                                           'id' => 'S.141',
                                           'package' => 'BioAssayData',
                                           'name' => 'ReporterDimension'
                                         },
                  'Fiducial' => {
                                  'parent' => 'Describable',
                                  'documentation' => 'A marking on the surface of the array that can be used to identify the array\'s origin, the coordinates of which are the fiducial\'s centroid.',
                                  'attrs' => [],
                                  'associations' => [
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'distanceUnit',
                                                                     'documentation' => 'The units the fiducial is measured in.',
                                                                     'class_id' => 'S.199',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 2',
                                                                                       'rank' => '2'
                                                                                     },
                                                                     'class_name' => 'DistanceUnit'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The units the fiducial is measured in.',
                                                                    'class_id' => 'S.59',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Fiducial'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '0..1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'fiducialType',
                                                                     'documentation' => 'A descriptive string that indicates the type of a fiducial (e.g. the chrome border on an Affymetrix array, a laser ablation mark).',
                                                                     'class_id' => 'S.185',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 1',
                                                                                       'rank' => '1'
                                                                                     },
                                                                     'class_name' => 'OntologyEntry'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'A descriptive string that indicates the type of a fiducial (e.g. the chrome border on an Affymetrix array, a laser ablation mark).',
                                                                    'class_id' => 'S.59',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Fiducial'
                                                                  }
                                                      },
                                                      {
                                                        'other' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => 'position',
                                                                     'documentation' => 'The position, relative to the upper left corner, of the fiducial',
                                                                     'class_id' => 'S.255',
                                                                     'aggregation' => 'none',
                                                                     'navigable' => 'true',
                                                                     'constraint' => {
                                                                                       'ordered' => 0,
                                                                                       'constraint' => 'rank: 3',
                                                                                       'rank' => '3'
                                                                                     },
                                                                     'class_name' => 'Position'
                                                                   },
                                                        'self' => {
                                                                    'cardinality' => '1',
                                                                    'ordering' => 'unordered',
                                                                    'name' => undef,
                                                                    'documentation' => 'The position, relative to the upper left corner, of the fiducial',
                                                                    'class_id' => 'S.59',
                                                                    'aggregation' => 'composite',
                                                                    'navigable' => 'false',
                                                                    'constraint' => undef,
                                                                    'class_name' => 'Fiducial'
                                                                  }
                                                      }
                                                    ],
                                  'abstract' => 'false',
                                  'methods' => [],
                                  'id' => 'S.59',
                                  'package' => 'Array',
                                  'name' => 'Fiducial'
                                },
                  'Zone' => {
                              'parent' => 'Identifiable',
                              'documentation' => 'Specifies the location of a zone on an array.',
                              'attrs' => [
                                           {
                                             'documentation' => 'row position in the ZoneGroup',
                                             'id' => 'S.26',
                                             'type' => 'int',
                                             'name' => 'row'
                                           },
                                           {
                                             'documentation' => 'column position in the ZoneGroup.',
                                             'id' => 'S.27',
                                             'type' => 'int',
                                             'name' => 'column'
                                           },
                                           {
                                             'documentation' => 'Boundary vertical upper left position relative to (0,0).',
                                             'id' => 'S.28',
                                             'type' => 'float',
                                             'name' => 'upperLeftX'
                                           },
                                           {
                                             'documentation' => 'Boundary horizontal upper left position relative to (0,0).',
                                             'id' => 'S.29',
                                             'type' => 'float',
                                             'name' => 'upperLeftY'
                                           },
                                           {
                                             'documentation' => 'Boundary vertical lower right position relative to (0,0).',
                                             'id' => 'S.30',
                                             'type' => 'float',
                                             'name' => 'lowerRightX'
                                           },
                                           {
                                             'documentation' => 'Boundary horizontal lower right position relative to (0,0).',
                                             'id' => 'S.31',
                                             'type' => 'float',
                                             'name' => 'lowerRightY'
                                           }
                                         ],
                              'associations' => [
                                                  {
                                                    'other' => {
                                                                 'cardinality' => '0..1',
                                                                 'ordering' => 'unordered',
                                                                 'name' => 'distanceUnit',
                                                                 'documentation' => 'Unit for the Zone attributes.',
                                                                 'class_id' => 'S.199',
                                                                 'aggregation' => 'none',
                                                                 'navigable' => 'true',
                                                                 'constraint' => {
                                                                                   'ordered' => 0,
                                                                                   'constraint' => 'rank: 1',
                                                                                   'rank' => '1'
                                                                                 },
                                                                 'class_name' => 'DistanceUnit'
                                                               },
                                                    'self' => {
                                                                'cardinality' => '1',
                                                                'ordering' => 'unordered',
                                                                'name' => undef,
                                                                'documentation' => 'Unit for the Zone attributes.',
                                                                'class_id' => 'S.25',
                                                                'aggregation' => 'composite',
                                                                'navigable' => 'false',
                                                                'constraint' => undef,
                                                                'class_name' => 'Zone'
                                                              }
                                                  }
                                                ],
                              'abstract' => 'false',
                              'methods' => [],
                              'id' => 'S.25',
                              'package' => 'ArrayDesign',
                              'name' => 'Zone'
                            },
                  'NodeValue' => {
                                   'parent' => 'Extendable',
                                   'documentation' => 'A value associated with the Node that can rank it in relation to the other nodes produced by the clustering algorithm.',
                                   'attrs' => [
                                                {
                                                  'documentation' => 'The name for this value.',
                                                  'id' => 'S.86',
                                                  'type' => 'String',
                                                  'name' => 'name'
                                                },
                                                {
                                                  'documentation' => 'The value for this NodeValue.',
                                                  'id' => 'S.87',
                                                  'type' => 'any',
                                                  'name' => 'value'
                                                }
                                              ],
                                   'associations' => [
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'scale',
                                                                      'documentation' => 'The scale (linear, log10, ln, etc.) of the value.',
                                                                      'class_id' => 'S.185',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 2',
                                                                                        'rank' => '2'
                                                                                      },
                                                                      'class_name' => 'OntologyEntry'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The scale (linear, log10, ln, etc.) of the value.',
                                                                     'class_id' => 'S.85',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'NodeValue'
                                                                   }
                                                       },
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '0..1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'dataType',
                                                                      'documentation' => 'The data type of the any element.',
                                                                      'class_id' => 'S.185',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 3',
                                                                                        'rank' => '3'
                                                                                      },
                                                                      'class_name' => 'OntologyEntry'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The data type of the any element.',
                                                                     'class_id' => 'S.85',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'NodeValue'
                                                                   }
                                                       },
                                                       {
                                                         'other' => {
                                                                      'cardinality' => '1',
                                                                      'ordering' => 'unordered',
                                                                      'name' => 'type',
                                                                      'documentation' => 'The type of value, distance, etc.',
                                                                      'class_id' => 'S.185',
                                                                      'aggregation' => 'none',
                                                                      'navigable' => 'true',
                                                                      'constraint' => {
                                                                                        'ordered' => 0,
                                                                                        'constraint' => 'rank: 1',
                                                                                        'rank' => '1'
                                                                                      },
                                                                      'class_name' => 'OntologyEntry'
                                                                    },
                                                         'self' => {
                                                                     'cardinality' => '1',
                                                                     'ordering' => 'unordered',
                                                                     'name' => undef,
                                                                     'documentation' => 'The type of value, distance, etc.',
                                                                     'class_id' => 'S.85',
                                                                     'aggregation' => 'composite',
                                                                     'navigable' => 'false',
                                                                     'constraint' => undef,
                                                                     'class_name' => 'NodeValue'
                                                                   }
                                                       }
                                                     ],
                                   'abstract' => 'false',
                                   'methods' => [],
                                   'id' => 'S.85',
                                   'package' => 'HigherLevelAnalysis',
                                   'name' => 'NodeValue'
                                 },
                  'ParameterizableApplication' => {
                                                    'subclasses' => [
                                                                      'ProtocolApplication',
                                                                      'HardwareApplication',
                                                                      'SoftwareApplication'
                                                                    ],
                                                    'parent' => 'Describable',
                                                    'documentation' => 'The interface that is the use of a Parameterizable class.',
                                                    'attrs' => [],
                                                    'associations' => [
                                                                        {
                                                                          'other' => {
                                                                                       'cardinality' => '0..N',
                                                                                       'ordering' => 'unordered',
                                                                                       'name' => 'parameterValues',
                                                                                       'documentation' => 'The parameter values for this Parameterizable Application.',
                                                                                       'class_id' => 'S.153',
                                                                                       'aggregation' => 'none',
                                                                                       'navigable' => 'true',
                                                                                       'constraint' => {
                                                                                                         'ordered' => 0,
                                                                                                         'constraint' => 'rank: 1',
                                                                                                         'rank' => '1'
                                                                                                       },
                                                                                       'class_name' => 'ParameterValue'
                                                                                     },
                                                                          'self' => {
                                                                                      'cardinality' => '1',
                                                                                      'ordering' => 'unordered',
                                                                                      'name' => undef,
                                                                                      'documentation' => 'The parameter values for this Parameterizable Application.',
                                                                                      'class_id' => 'S.168',
                                                                                      'aggregation' => 'composite',
                                                                                      'navigable' => 'false',
                                                                                      'constraint' => undef,
                                                                                      'class_name' => 'ParameterizableApplication'
                                                                                    }
                                                                        }
                                                                      ],
                                                    'abstract' => 'true',
                                                    'methods' => [],
                                                    'id' => 'S.168',
                                                    'package' => 'Protocol',
                                                    'name' => 'ParameterizableApplication'
                                                  },
                  'FeatureReporterMap' => {
                                            'parent' => 'DesignElementMap',
                                            'documentation' => 'A FeatureReporterMap is the description of how source features are transformed into a target reporter.  These would map replicate features for a reporter to the reporter.',
                                            'attrs' => [],
                                            'associations' => [
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'reporter',
                                                                               'documentation' => 'Associates features with their reporter.',
                                                                               'class_id' => 'S.258',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 1',
                                                                                                 'rank' => '1'
                                                                                               },
                                                                               'class_name' => 'Reporter'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '0..N',
                                                                              'ordering' => 'unordered',
                                                                              'name' => 'featureReporterMaps',
                                                                              'documentation' => 'Associates features with their reporter.',
                                                                              'class_id' => 'S.269',
                                                                              'aggregation' => 'none',
                                                                              'navigable' => 'true',
                                                                              'constraint' => {
                                                                                                'ordered' => 0,
                                                                                                'constraint' => 'rank: 4',
                                                                                                'rank' => '4'
                                                                                              },
                                                                              'class_name' => 'FeatureReporterMap'
                                                                            }
                                                                },
                                                                {
                                                                  'other' => {
                                                                               'cardinality' => '1..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => 'featureInformationSources',
                                                                               'documentation' => 'Typically, the features on an array that are manufactured with this reporter\'s BioSequence.',
                                                                               'class_id' => 'S.267',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'true',
                                                                               'constraint' => {
                                                                                                 'ordered' => 0,
                                                                                                 'constraint' => 'rank: 2',
                                                                                                 'rank' => '2'
                                                                                               },
                                                                               'class_name' => 'FeatureInformation'
                                                                             },
                                                                  'self' => {
                                                                              'cardinality' => '1',
                                                                              'ordering' => 'unordered',
                                                                              'name' => undef,
                                                                              'documentation' => 'Typically, the features on an array that are manufactured with this reporter\'s BioSequence.',
                                                                              'class_id' => 'S.269',
                                                                              'aggregation' => 'composite',
                                                                              'navigable' => 'false',
                                                                              'constraint' => undef,
                                                                              'class_name' => 'FeatureReporterMap'
                                                                            }
                                                                }
                                                              ],
                                            'abstract' => 'false',
                                            'methods' => [],
                                            'id' => 'S.269',
                                            'package' => 'DesignElement',
                                            'name' => 'FeatureReporterMap'
                                          },
                  'CompositeCompositeMap' => {
                                               'parent' => 'DesignElementMap',
                                               'documentation' => 'A CompositeCompositeMap is the description of how source CompositeSequences are transformed into a target CompositeSequence.   For instance, several CompositeSequences could represent different sequence regions for a Gene and could be mapped to different CompositeSequences, each representing a different splice variant for that Gene.',
                                               'attrs' => [],
                                               'associations' => [
                                                                   {
                                                                     'other' => {
                                                                                  'cardinality' => '1..N',
                                                                                  'ordering' => 'unordered',
                                                                                  'name' => 'compositePositionSources',
                                                                                  'documentation' => 'Association to the CompositeSequences that compose this CompositeSequence and where those CompositeSequences occur.',
                                                                                  'class_id' => 'S.260',
                                                                                  'aggregation' => 'none',
                                                                                  'navigable' => 'true',
                                                                                  'constraint' => {
                                                                                                    'ordered' => 0,
                                                                                                    'constraint' => 'rank: 2',
                                                                                                    'rank' => '2'
                                                                                                  },
                                                                                  'class_name' => 'CompositePosition'
                                                                                },
                                                                     'self' => {
                                                                                 'cardinality' => '1',
                                                                                 'ordering' => 'unordered',
                                                                                 'name' => undef,
                                                                                 'documentation' => 'Association to the CompositeSequences that compose this CompositeSequence and where those CompositeSequences occur.',
                                                                                 'class_id' => 'S.268',
                                                                                 'aggregation' => 'composite',
                                                                                 'navigable' => 'false',
                                                                                 'constraint' => undef,
                                                                                 'class_name' => 'CompositeCompositeMap'
                                                                               }
                                                                   },
                                                                   {
                                                                     'other' => {
                                                                                  'cardinality' => '1',
                                                                                  'ordering' => 'unordered',
                                                                                  'name' => 'compositeSequence',
                                                                                  'documentation' => 'A map to the compositeSequences that compose this CompositeSequence.',
                                                                                  'class_id' => 'S.261',
                                                                                  'aggregation' => 'none',
                                                                                  'navigable' => 'true',
                                                                                  'constraint' => {
                                                                                                    'ordered' => 0,
                                                                                                    'constraint' => 'rank: 1',
                                                                                                    'rank' => '1'
                                                                                                  },
                                                                                  'class_name' => 'CompositeSequence'
                                                                                },
                                                                     'self' => {
                                                                                 'cardinality' => '0..N',
                                                                                 'ordering' => 'unordered',
                                                                                 'name' => 'compositeCompositeMaps',
                                                                                 'documentation' => 'A map to the compositeSequences that compose this CompositeSequence.',
                                                                                 'class_id' => 'S.268',
                                                                                 'aggregation' => 'none',
                                                                                 'navigable' => 'true',
                                                                                 'constraint' => {
                                                                                                   'ordered' => 0,
                                                                                                   'constraint' => 'rank: 2',
                                                                                                   'rank' => '2'
                                                                                                 },
                                                                                 'class_name' => 'CompositeCompositeMap'
                                                                               }
                                                                   }
                                                                 ],
                                               'abstract' => 'false',
                                               'methods' => [],
                                               'id' => 'S.268',
                                               'package' => 'DesignElement',
                                               'name' => 'CompositeCompositeMap'
                                             },
                  'Channel' => {
                                 'parent' => 'Identifiable',
                                 'documentation' => 'A channel represents an independent acquisition scheme for the ImageAcquisition event, typically a wavelength.',
                                 'attrs' => [],
                                 'associations' => [
                                                     {
                                                       'other' => {
                                                                    'cardinality' => '0..N',
                                                                    'ordering' => 'unordered',
                                                                    'name' => 'labels',
                                                                    'documentation' => 'The compound used to label the extract.',
                                                                    'class_id' => 'S.75',
                                                                    'aggregation' => 'none',
                                                                    'navigable' => 'true',
                                                                    'constraint' => {
                                                                                      'ordered' => 0,
                                                                                      'constraint' => 'rank: 1',
                                                                                      'rank' => '1'
                                                                                    },
                                                                    'class_name' => 'Compound'
                                                                  },
                                                       'self' => {
                                                                   'cardinality' => '0..N',
                                                                   'ordering' => 'unordered',
                                                                   'name' => undef,
                                                                   'documentation' => 'The compound used to label the extract.',
                                                                   'class_id' => 'S.94',
                                                                   'aggregation' => 'none',
                                                                   'navigable' => 'false',
                                                                   'constraint' => undef,
                                                                   'class_name' => 'Channel'
                                                                 }
                                                     }
                                                   ],
                                 'abstract' => 'false',
                                 'methods' => [],
                                 'id' => 'S.94',
                                 'package' => 'BioAssay',
                                 'name' => 'Channel'
                               },
                  'MeasuredBioAssay' => {
                                          'parent' => 'BioAssay',
                                          'documentation' => 'A measured bioAssay is the direct processing of information in a physical bioAssay by the featureExtraction event.  Often uses images which are referenced through the physical bioAssay.',
                                          'attrs' => [],
                                          'associations' => [
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..1',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'featureExtraction',
                                                                             'documentation' => 'The association between the MeasuredBioAssay and the FeatureExtraction Event.',
                                                                             'class_id' => 'S.97',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 1',
                                                                                               'rank' => '1'
                                                                                             },
                                                                             'class_name' => 'FeatureExtraction'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'measuredBioAssayTarget',
                                                                            'documentation' => 'The association between the MeasuredBioAssay and the FeatureExtraction Event.',
                                                                            'class_id' => 'S.95',
                                                                            'aggregation' => 'composite',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 2',
                                                                                              'rank' => '2'
                                                                                            },
                                                                            'class_name' => 'MeasuredBioAssay'
                                                                          }
                                                              },
                                                              {
                                                                'other' => {
                                                                             'cardinality' => '0..N',
                                                                             'ordering' => 'unordered',
                                                                             'name' => 'measuredBioAssayData',
                                                                             'documentation' => 'The data associated with the MeasuredBioAssay.',
                                                                             'class_id' => 'S.127',
                                                                             'aggregation' => 'none',
                                                                             'navigable' => 'true',
                                                                             'constraint' => {
                                                                                               'ordered' => 0,
                                                                                               'constraint' => 'rank: 2',
                                                                                               'rank' => '2'
                                                                                             },
                                                                             'class_name' => 'MeasuredBioAssayData'
                                                                           },
                                                                'self' => {
                                                                            'cardinality' => '1..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => undef,
                                                                            'documentation' => 'The data associated with the MeasuredBioAssay.',
                                                                            'class_id' => 'S.95',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'false',
                                                                            'constraint' => undef,
                                                                            'class_name' => 'MeasuredBioAssay'
                                                                          }
                                                              }
                                                            ],
                                          'abstract' => 'false',
                                          'methods' => [],
                                          'id' => 'S.95',
                                          'package' => 'BioAssay',
                                          'name' => 'MeasuredBioAssay'
                                        },
                  'CompoundMeasurement' => {
                                             'parent' => 'Extendable',
                                             'documentation' => 'A CompoundMeasurement is a pairing of a source Compound and an amount (Measurement) of that Compound.',
                                             'attrs' => [],
                                             'associations' => [
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'compound',
                                                                                'documentation' => 'A Compound to be used to create another Compound.',
                                                                                'class_id' => 'S.75',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 1',
                                                                                                  'rank' => '1'
                                                                                                },
                                                                                'class_name' => 'Compound'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '0..N',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'A Compound to be used to create another Compound.',
                                                                               'class_id' => 'S.77',
                                                                               'aggregation' => 'none',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'CompoundMeasurement'
                                                                             }
                                                                 },
                                                                 {
                                                                   'other' => {
                                                                                'cardinality' => '0..1',
                                                                                'ordering' => 'unordered',
                                                                                'name' => 'measurement',
                                                                                'documentation' => 'The amount of the Compound.',
                                                                                'class_id' => 'S.190',
                                                                                'aggregation' => 'none',
                                                                                'navigable' => 'true',
                                                                                'constraint' => {
                                                                                                  'ordered' => 0,
                                                                                                  'constraint' => 'rank: 2',
                                                                                                  'rank' => '2'
                                                                                                },
                                                                                'class_name' => 'Measurement'
                                                                              },
                                                                   'self' => {
                                                                               'cardinality' => '1',
                                                                               'ordering' => 'unordered',
                                                                               'name' => undef,
                                                                               'documentation' => 'The amount of the Compound.',
                                                                               'class_id' => 'S.77',
                                                                               'aggregation' => 'composite',
                                                                               'navigable' => 'false',
                                                                               'constraint' => undef,
                                                                               'class_name' => 'CompoundMeasurement'
                                                                             }
                                                                 }
                                                               ],
                                             'abstract' => 'false',
                                             'methods' => [],
                                             'id' => 'S.77',
                                             'package' => 'BioMaterial',
                                             'name' => 'CompoundMeasurement'
                                           },
                  'Parameterizable' => {
                                         'subclasses' => [
                                                           'Protocol',
                                                           'Software',
                                                           'Hardware'
                                                         ],
                                         'parent' => 'Identifiable',
                                         'documentation' => 'The Parameterizable interface encapsulates the association of Parameters with ParameterValues.',
                                         'attrs' => [
                                                      {
                                                        'documentation' => 'Where an instantiated Parameterizable is located.',
                                                        'id' => 'S.167',
                                                        'type' => 'String',
                                                        'name' => 'URI'
                                                      }
                                                    ],
                                         'associations' => [
                                                             {
                                                               'other' => {
                                                                            'cardinality' => '0..N',
                                                                            'ordering' => 'unordered',
                                                                            'name' => 'parameterTypes',
                                                                            'documentation' => 'The description of the parameters for the Parameterizable class instance.',
                                                                            'class_id' => 'S.152',
                                                                            'aggregation' => 'none',
                                                                            'navigable' => 'true',
                                                                            'constraint' => {
                                                                                              'ordered' => 0,
                                                                                              'constraint' => 'rank: 1',
                                                                                              'rank' => '1'
                                                                                            },
                                                                            'class_name' => 'Parameter'
                                                                          },
                                                               'self' => {
                                                                           'cardinality' => '1',
                                                                           'ordering' => 'unordered',
                                                                           'name' => undef,
                                                                           'documentation' => 'The description of the parameters for the Parameterizable class instance.',
                                                                           'class_id' => 'S.166',
                                                                           'aggregation' => 'composite',
                                                                           'navigable' => 'false',
                                                                           'constraint' => undef,
                                                                           'class_name' => 'Parameterizable'
                                                                         }
                                                             }
                                                           ],
                                         'abstract' => 'true',
                                         'methods' => [],
                                         'id' => 'S.166',
                                         'package' => 'Protocol',
                                         'name' => 'Parameterizable'
                                       }
                };

$XMI::packages = {
                   'Description' => [
                                      'Description',
                                      'DatabaseEntry',
                                      'Database',
                                      'ExternalReference',
                                      'OntologyEntry'
                                    ],
                   'AuditAndSecurity' => [
                                           'Person',
                                           'Security',
                                           'Audit',
                                           'Organization',
                                           'SecurityGroup',
                                           'Contact'
                                         ],
                   'BioEvent' => [
                                   'BioEvent',
                                   'Map'
                                 ],
                   'Measurement' => [
                                      'Measurement',
                                      'Unit',
                                      'TimeUnit',
                                      'DistanceUnit',
                                      'TemperatureUnit',
                                      'QuantityUnit',
                                      'MassUnit',
                                      'VolumeUnit',
                                      'ConcentrationUnit'
                                    ],
                   'MAGE' => [
                               'NameValueType',
                               'Extendable',
                               'Identifiable',
                               'Describable'
                             ],
                   'BQS' => [
                              'BibliographicReference'
                            ],
                   'Protocol' => [
                                   'Protocol',
                                   'Parameter',
                                   'ParameterValue',
                                   'ProtocolApplication',
                                   'Software',
                                   'Hardware',
                                   'HardwareApplication',
                                   'SoftwareApplication',
                                   'Parameterizable',
                                   'ParameterizableApplication'
                                 ],
                   'BioAssay' => [
                                   'PhysicalBioAssay',
                                   'DerivedBioAssay',
                                   'Image',
                                   'BioAssay',
                                   'Channel',
                                   'MeasuredBioAssay',
                                   'BioAssayCreation',
                                   'FeatureExtraction',
                                   'Hybridization',
                                   'ImageAcquisition',
                                   'BioAssayTreatment'
                                 ],
                   'QuantitationType' => [
                                           'StandardQuantitationType',
                                           'QuantitationType',
                                           'SpecializedQuantitationType',
                                           'DerivedSignal',
                                           'MeasuredSignal',
                                           'Error',
                                           'PValue',
                                           'ExpectedValue',
                                           'Ratio',
                                           'ConfidenceIndicator',
                                           'PresentAbsent',
                                           'Failed'
                                         ],
                   'DesignElement' => [
                                        'DesignElement',
                                        'Position',
                                        'Reporter',
                                        'ReporterPosition',
                                        'CompositePosition',
                                        'CompositeSequence',
                                        'Feature',
                                        'MismatchInformation',
                                        'FeatureInformation',
                                        'CompositeCompositeMap',
                                        'FeatureReporterMap',
                                        'ReporterCompositeMap',
                                        'FeatureLocation'
                                      ],
                   'BioMaterial' => [
                                      'BioSource',
                                      'BioMaterial',
                                      'LabeledExtract',
                                      'BioSample',
                                      'Compound',
                                      'CompoundMeasurement',
                                      'BioMaterialMeasurement',
                                      'Treatment'
                                    ],
                   'HigherLevelAnalysis' => [
                                              'BioAssayDataCluster',
                                              'Node',
                                              'NodeContents',
                                              'NodeValue'
                                            ],
                   'BioAssayData' => [
                                       'BioAssayData',
                                       'QuantitationTypeDimension',
                                       'BioAssayMapping',
                                       'DesignElementDimension',
                                       'BioAssayDatum',
                                       'DerivedBioAssayData',
                                       'MeasuredBioAssayData',
                                       'QuantitationTypeMapping',
                                       'DesignElementMapping',
                                       'BioDataCube',
                                       'BioDataValues',
                                       'BioDataTuples',
                                       'BioAssayDimension',
                                       'QuantitationTypeMap',
                                       'Transformation',
                                       'DesignElementMap',
                                       'BioAssayMap',
                                       'CompositeSequenceDimension',
                                       'ReporterDimension',
                                       'FeatureDimension'
                                     ],
                   'Experiment' => [
                                     'Experiment',
                                     'ExperimentDesign',
                                     'ExperimentalFactor',
                                     'FactorValue'
                                   ],
                   'BioSequence' => [
                                      'SeqFeature',
                                      'SeqFeatureLocation',
                                      'BioSequence',
                                      'SequencePosition'
                                    ],
                   'Array' => [
                                'Array',
                                'FeatureDefect',
                                'ArrayGroup',
                                'ArrayManufacture',
                                'ArrayManufactureDeviation',
                                'Fiducial',
                                'ManufactureLIMS',
                                'ManufactureLIMSBiomaterial',
                                'PositionDelta',
                                'ZoneDefect'
                              ],
                   'ArrayDesign' => [
                                      'ArrayDesign',
                                      'PhysicalArrayDesign',
                                      'ZoneLayout',
                                      'ZoneGroup',
                                      'Zone',
                                      'ReporterGroup',
                                      'FeatureGroup',
                                      'DesignElementGroup',
                                      'CompositeGroup'
                                    ]
                 };

