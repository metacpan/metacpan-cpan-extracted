

#define __supportrev_generated_c_

#include "supportrev_generated.h"
#include "supportrev.h"
#include "support.h"


#if defined(ARSPERL_UNDEF_MALLOC) && defined(malloc)
 #undef malloc
 #undef calloc
 #undef realloc
 #undef free
#endif




#if AR_CURRENT_API_VERSION >= 13
int
rev_ARActiveLinkSvcActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARActiveLinkSvcActionStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARActiveLinkSvcActionStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARActiveLinkSvcActionStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "sampleSchema", 255 );
						val = hv_fetch( h, "sampleSchema", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleSchema, SvPV_nolen(*val), sizeof(p->sampleSchema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleSchema\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "inputFieldMapping", 255 );
						val = hv_fetch( h, "inputFieldMapping", 17, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldAssignList( ctrl, h, k, &(p->inputFieldMapping) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"inputFieldMapping\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "sampleServer", 255 );
						val = hv_fetch( h, "sampleServer", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleServer, SvPV_nolen(*val), sizeof(p->sampleServer) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleServer\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "requestIdMap", 255 );
						val = hv_fetch( h, "requestIdMap", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->requestIdMap = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"requestIdMap\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "serviceSchema", 255 );
						val = hv_fetch( h, "serviceSchema", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->serviceSchema, SvPV_nolen(*val), sizeof(p->serviceSchema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"serviceSchema\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "outputFieldMapping", 255 );
						val = hv_fetch( h, "outputFieldMapping", 18, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldAssignList( ctrl, h, k, &(p->outputFieldMapping) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"outputFieldMapping\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "serverName", 255 );
						val = hv_fetch( h, "serverName", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->serverName, SvPV_nolen(*val), sizeof(p->serverName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"serverName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARActiveLinkSvcActionStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARActiveLinkSvcActionStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARActiveLinkSvcActionStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARActiveLinkSvcActionStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARAttachLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARAttachLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAttachLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARAttachLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "maxSize", 255 );
						val = hv_fetch( h, "maxSize", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->maxSize = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"maxSize\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "attachType", 255 );
						val = hv_fetch( h, "attachType", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->attachType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"attachType\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAttachLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARAttachLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARAttachLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAttachLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 12
int
rev_ARAuditInfoStruct( ARControlStruct *ctrl, HV *h, char *k, ARAuditInfoStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAuditInfoStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARAuditInfoStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "enable", 255 );
						val = hv_fetch( h, "enable", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->enable = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"enable\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "query", 255 );
						val = hv_fetch( h, "query", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARQualifierStruct( ctrl, h, k, &(p->query) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"query\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "style", 255 );
						val = hv_fetch( h, "style", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->style = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"style\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "formName", 255 );
						val = hv_fetch( h, "formName", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->formName, SvPV_nolen(*val), sizeof(p->formName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"formName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAuditInfoStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARAuditInfoStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARAuditInfoStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAuditInfoStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARAutomationStruct( ARControlStruct *ctrl, HV *h, char *k, ARAutomationStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAutomationStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARAutomationStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "isVisible", 255 );
						val = hv_fetch( h, "isVisible", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"true") ){
									p->isVisible = TRUE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"false") ){
									p->isVisible = FALSE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARAutomationStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"isVisible\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "autoServerName", 255 );
						val = hv_fetch( h, "autoServerName", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->autoServerName = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"autoServerName\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "action", 255 );
						val = hv_fetch( h, "action", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->action = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"action\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "methodList", 255 );
						val = hv_fetch( h, "methodList", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARCOMMethodList( ctrl, h, k, &(p->methodList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"methodList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "clsId", 255 );
						val = hv_fetch( h, "clsId", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->clsId = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"clsId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAutomationStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARAutomationStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARAutomationStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARAutomationStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 11
int
rev_ARBulkEntryReturn( ARControlStruct *ctrl, HV *h, char *k, ARBulkEntryReturn *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARBulkEntryReturn: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				
							}else if( hv_exists(h,"xmlCreateEntryReturn",20) ){
								p->entryCallType = AR_BULK_ENTRY_XMLCREATE;
								k = "xmlCreateEntryReturn";
				
				
							}else if( hv_exists(h,"setEntryReturn",14) ){
								p->entryCallType = AR_BULK_ENTRY_SET;
								k = "setEntryReturn";
				
				
							}else if( hv_exists(h,"xmlSetEntryReturn",17) ){
								p->entryCallType = AR_BULK_ENTRY_XMLSET;
								k = "xmlSetEntryReturn";
				
				
							}else if( hv_exists(h,"mergeEntryReturn",16) ){
								p->entryCallType = AR_BULK_ENTRY_MERGE;
								k = "mergeEntryReturn";
				
				
							}else if( hv_exists(h,"xmlDeleteEntryReturn",20) ){
								p->entryCallType = AR_BULK_ENTRY_XMLDELETE;
								k = "xmlDeleteEntryReturn";
				
				
							}else if( hv_exists(h,"deleteEntryReturn",17) ){
								p->entryCallType = AR_BULK_ENTRY_DELETE;
								k = "deleteEntryReturn";
				
				
							}else if( hv_exists(h,"createEntryReturn",17) ){
								p->entryCallType = AR_BULK_ENTRY_CREATE;
								k = "createEntryReturn";
				
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: map error" );
							}
				
				
							switch( p->entryCallType ){
				
							case AR_BULK_ENTRY_XMLCREATE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "xmlCreateEntryReturn", 255 );
										val = hv_fetch( h, "xmlCreateEntryReturn", 20, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARXMLEntryReturn( ctrl, h, k, &(p->u.xmlCreateEntryReturn) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"xmlCreateEntryReturn\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_BULK_ENTRY_SET:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "setEntryReturn", 255 );
										val = hv_fetch( h, "setEntryReturn", 14, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARStatusList( ctrl, h, k, &(p->u.setEntryReturn) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"setEntryReturn\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_BULK_ENTRY_XMLSET:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "xmlSetEntryReturn", 255 );
										val = hv_fetch( h, "xmlSetEntryReturn", 17, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARXMLEntryReturn( ctrl, h, k, &(p->u.xmlSetEntryReturn) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"xmlSetEntryReturn\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_BULK_ENTRY_MERGE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "mergeEntryReturn", 255 );
										val = hv_fetch( h, "mergeEntryReturn", 16, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_AREntryReturn( ctrl, h, k, &(p->u.mergeEntryReturn) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"mergeEntryReturn\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_BULK_ENTRY_XMLDELETE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "xmlDeleteEntryReturn", 255 );
										val = hv_fetch( h, "xmlDeleteEntryReturn", 20, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARStatusList( ctrl, h, k, &(p->u.xmlDeleteEntryReturn) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"xmlDeleteEntryReturn\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_BULK_ENTRY_DELETE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "deleteEntryReturn", 255 );
										val = hv_fetch( h, "deleteEntryReturn", 17, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARStatusList( ctrl, h, k, &(p->u.deleteEntryReturn) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"deleteEntryReturn\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_BULK_ENTRY_CREATE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "createEntryReturn", 255 );
										val = hv_fetch( h, "createEntryReturn", 17, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_AREntryReturn( ctrl, h, k, &(p->u.createEntryReturn) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"createEntryReturn\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							default:
								sprintf( errText, "rev_ARBulkEntryReturn: invalid switch value %d", p->entryCallType );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturn: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 11
int
rev_ARBulkEntryReturnList( ARControlStruct *ctrl, HV *h, char *k, ARBulkEntryReturnList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturnList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARBulkEntryReturnList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->entryReturnList = (ARBulkEntryReturn*) MALLOCNN( sizeof(ARBulkEntryReturn) * num );
							/* if( p->entryReturnList == NULL ){
								croak( "rev_ARBulkEntryReturnList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARBulkEntryReturn( ctrl, h, k, &(p->entryReturnList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturnList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturnList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARBulkEntryReturnList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARBulkEntryReturnList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARBulkEntryReturnList: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARCOMMethodList( ARControlStruct *ctrl, HV *h, char *k, ARCOMMethodList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCOMMethodList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->methodList = (ARCOMMethodStruct*) MALLOCNN( sizeof(ARCOMMethodStruct) * num );
							/* if( p->methodList == NULL ){
								croak( "rev_ARCOMMethodList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARCOMMethodStruct( ctrl, h, k, &(p->methodList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMMethodList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMMethodList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCOMMethodParmList( ARControlStruct *ctrl, HV *h, char *k, ARCOMMethodParmList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodParmList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCOMMethodParmList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->parameterList = (ARCOMMethodParmStruct*) MALLOCNN( sizeof(ARCOMMethodParmStruct) * num );
							/* if( p->parameterList == NULL ){
								croak( "rev_ARCOMMethodParmList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARCOMMethodParmStruct( ctrl, h, k, &(p->parameterList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodParmList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodParmList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMMethodParmList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMMethodParmList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodParmList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCOMMethodParmStruct( ARControlStruct *ctrl, HV *h, char *k, ARCOMMethodParmStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodParmStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCOMMethodParmStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "parmType", 255 );
						val = hv_fetch( h, "parmType", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->parmType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"parmType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "parmValue", 255 );
						val = hv_fetch( h, "parmValue", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARCOMValueStruct( ctrl, h, k, &(p->parmValue) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"parmValue\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "parmName", 255 );
						val = hv_fetch( h, "parmName", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->parmName = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"parmName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodParmStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMMethodParmStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMMethodParmStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodParmStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCOMMethodStruct( ARControlStruct *ctrl, HV *h, char *k, ARCOMMethodStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCOMMethodStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "methodName", 255 );
						val = hv_fetch( h, "methodName", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->methodName = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"methodName\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "methodIId", 255 );
						val = hv_fetch( h, "methodIId", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->methodIId = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"methodIId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "methodType", 255 );
						val = hv_fetch( h, "methodType", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->methodType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"methodType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "parameterList", 255 );
						val = hv_fetch( h, "parameterList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARCOMMethodParmList( ctrl, h, k, &(p->parameterList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"parameterList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "methodValue", 255 );
						val = hv_fetch( h, "methodValue", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARCOMValueStruct( ctrl, h, k, &(p->methodValue) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"methodValue\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMMethodStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMMethodStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMMethodStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCOMValueStruct( ARControlStruct *ctrl, HV *h, char *k, ARCOMValueStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMValueStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCOMValueStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMValueStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				
							}else if( hv_exists(h,"value",5) ){
								p->valueType = AR_COM_PARM_VALUE;
								k = "value";
				
				
							}else if( hv_exists(h,"fieldId",7) ){
								p->valueType = AR_COM_PARM_FIELDID;
								k = "fieldId";
				
							}else if( 1 ){
							    p->valueType = AR_COM_PARM_NULL;
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMValueStruct: map error" );
							}
				
				
							switch( p->valueType ){
				
							case AR_COM_PARM_VALUE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "value", 255 );
										val = hv_fetch( h, "value", 5, 0 );
										if( val && *val && (SvOK(*val) || SvTYPE(*val) == SVt_NULL) ){
											{
												rev_ARValueStruct( ctrl, h, k, "dataType", &(p->u.value) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"value\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMValueStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COM_PARM_FIELDID:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldId", 255 );
										val = hv_fetch( h, "fieldId", 7, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.fieldId = SvIV(*val);
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMValueStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							case AR_COM_PARM_NULL:
								break;
							default:
								sprintf( errText, "rev_ARCOMValueStruct: invalid switch value %d", p->valueType );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "valueIId", 255 );
						val = hv_fetch( h, "valueIId", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->valueIId = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueIId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "valueType", 255 );
						val = hv_fetch( h, "valueType", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->valueType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "transId", 255 );
						val = hv_fetch( h, "transId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->transId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"transId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMValueStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMValueStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCOMValueStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCOMValueStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCallGuideStruct( ARControlStruct *ctrl, HV *h, char *k, ARCallGuideStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCallGuideStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCallGuideStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				#if AR_CURRENT_API_VERSION >= 10
					{
						SV **val;
						strncpy( k, "inputValueFieldPairs", 255 );
						val = hv_fetch( h, "inputValueFieldPairs", 20, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldAssignList( ctrl, h, k, &(p->inputValueFieldPairs) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"inputValueFieldPairs\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "guideName", 255 );
						val = hv_fetch( h, "guideName", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->guideName, SvPV_nolen(*val), sizeof(p->guideName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"guideName\"" );
							return -1;
						}
					}
				
				#if AR_CURRENT_API_VERSION >= 10
					{
						SV **val;
						strncpy( k, "sampleGuide", 255 );
						val = hv_fetch( h, "sampleGuide", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleGuide, SvPV_nolen(*val), sizeof(p->sampleGuide) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleGuide\"" );
							return -1;
						}
					}
				#endif
				#if AR_CURRENT_API_VERSION >= 10
					{
						SV **val;
						strncpy( k, "sampleServer", 255 );
						val = hv_fetch( h, "sampleServer", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleServer, SvPV_nolen(*val), sizeof(p->sampleServer) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleServer\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "loopTable", 255 );
						val = hv_fetch( h, "loopTable", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->guideTableId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"loopTable\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "guideMode", 255 );
						val = hv_fetch( h, "guideMode", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->guideMode = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"guideMode\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "serverName", 255 );
						val = hv_fetch( h, "serverName", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->serverName, SvPV_nolen(*val), sizeof(p->serverName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"serverName\"" );
							return -1;
						}
					}
				
				#if AR_CURRENT_API_VERSION >= 10
					{
						SV **val;
						strncpy( k, "outputValueFieldPairs", 255 );
						val = hv_fetch( h, "outputValueFieldPairs", 21, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldAssignList( ctrl, h, k, &(p->outputValueFieldPairs) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"outputValueFieldPairs\"" );
							return -1;
						}
					}
				#endif
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCallGuideStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCallGuideStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCallGuideStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCallGuideStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				#if AR_CURRENT_API_VERSION >= 14
					{
						SV **val;
						strncpy( k, "lengthUnits", 255 );
						val = hv_fetch( h, "lengthUnits", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"char") ){
									p->lengthUnits = AR_LENGTH_UNIT_CHAR;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"byte") ){
									p->lengthUnits = AR_LENGTH_UNIT_BYTE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARCharLimitsStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"lengthUnits\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "pattern", 255 );
						val = hv_fetch( h, "pattern", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->pattern = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"pattern\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "charMenu", 255 );
						val = hv_fetch( h, "charMenu", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->charMenu, SvPV_nolen(*val), sizeof(p->charMenu) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"charMenu\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "maxLength", 255 );
						val = hv_fetch( h, "maxLength", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->maxLength = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"maxLength\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "match", 255 );
						val = hv_fetch( h, "match", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"leading") ){
									p->qbeMatchOperation = AR_QBE_MATCH_LEADING;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"equal") ){
									p->qbeMatchOperation = AR_QBE_MATCH_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"anywhere") ){
									p->qbeMatchOperation = AR_QBE_MATCH_ANYWHERE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARCharLimitsStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"match\"" );
							return -1;
						}
					}
				
				#if AR_CURRENT_API_VERSION >= 14
					{
						SV **val;
						strncpy( k, "storageOptionForCLOB", 255 );
						val = hv_fetch( h, "storageOptionForCLOB", 20, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"inrow") ){
									p->storageOptionForCLOB = AR_STORE_OPT_INROW;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"default") ){
									p->storageOptionForCLOB = AR_STORE_OPT_DEF;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"outrow") ){
									p->storageOptionForCLOB = AR_STORE_OPT_OUTROW;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARCharLimitsStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"storageOptionForCLOB\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "fullTextOptions", 255 );
						val = hv_fetch( h, "fullTextOptions", 15, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"indexed") ){
									p->fullTextOptions = AR_FULLTEXT_OPTIONS_INDEXED;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"none") ){
									p->fullTextOptions = AR_FULLTEXT_OPTIONS_NONE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARCharLimitsStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fullTextOptions\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "menuStyle", 255 );
						val = hv_fetch( h, "menuStyle", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"append") ){
									p->menuStyle = AR_MENU_APPEND;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"overwrite") ){
									p->menuStyle = AR_MENU_OVERWRITE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARCharLimitsStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"menuStyle\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharMenuDDFieldStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuDDFieldStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDFieldStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharMenuDDFieldStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "fieldType", 255 );
						val = hv_fetch( h, "fieldType", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fieldType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schema", 255 );
						val = hv_fetch( h, "schema", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->schema, SvPV_nolen(*val), sizeof(p->schema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schema\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDFieldStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuDDFieldStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuDDFieldStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDFieldStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharMenuDDFormStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuDDFormStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDFormStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharMenuDDFormStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "includeHidden", 255 );
						val = hv_fetch( h, "includeHidden", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"true") ){
									p->includeHidden = TRUE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"false") ){
									p->includeHidden = FALSE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARCharMenuDDFormStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"includeHidden\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schemaType", 255 );
						val = hv_fetch( h, "schemaType", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->schemaType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schemaType\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDFormStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuDDFormStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuDDFormStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDFormStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharMenuDDStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuDDStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharMenuDDStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
							// pcase = SvPV_nolen(*val);
							// p->structType = caseLookUpTypeNumber( (TypeMapStruct*) structType, pcase );
							HV *h2 = (HV* ) SvRV((SV*) *val);
							SV** val = hv_fetch( h2, "structType", 10, 0 );
							p->structType = SvIV(*val);
				
				
							switch( p->structType ){
				
							case AR_CHAR_MENU_DD_FIELD:
								{
									rev_ARCharMenuDDFieldStruct( ctrl, h, k, &(p->u.fieldDefn) );
								}
								break;
				
				
							case AR_CHAR_MENU_DD_FORM:
								{
									rev_ARCharMenuDDFormStruct( ctrl, h, k, &(p->u.formDefn) );
								}
								break;
				
							default:
								sprintf( errText, "rev_ARCharMenuDDStruct: invalid switch value %d", p->structType );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "structType", 255 );
						val = hv_fetch( h, "structType", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->structType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"structType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "nameType", 255 );
						val = hv_fetch( h, "nameType", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->nameType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"nameType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "valueFormat", 255 );
						val = hv_fetch( h, "valueFormat", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->valueFormat = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueFormat\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "server", 255 );
						val = hv_fetch( h, "server", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->server, SvPV_nolen(*val), sizeof(p->server) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"server\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuDDStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuDDStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuDDStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharMenuFileStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuFileStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuFileStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharMenuFileStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "filename", 255 );
						val = hv_fetch( h, "filename", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->filename = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"filename\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fileLocation", 255 );
						val = hv_fetch( h, "fileLocation", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fileLocation = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fileLocation\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuFileStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuFileStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuFileStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuFileStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharMenuList( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharMenuList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->charMenuList = (ARCharMenuItemStruct*) MALLOCNN( sizeof(ARCharMenuItemStruct) * num );
							/* if( p->charMenuList == NULL ){
								croak( "rev_ARCharMenuList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARCharMenuItemStruct( ctrl, h, k, &(p->charMenuList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharMenuQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuQueryStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuQueryStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharMenuQueryStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "labelField", 255 );
						val = hv_fetch( h, "labelField", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								copyUIntArray( AR_MAX_LEVELS_DYNAMIC_MENU, p->labelField, *val );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"labelField\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "qualifier", 255 );
						val = hv_fetch( h, "qualifier", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARQualifierStruct( ctrl, h, k, &(p->qualifier) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"qualifier\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "sortOnLabel", 255 );
						val = hv_fetch( h, "sortOnLabel", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->sortOnLabel = (char) SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sortOnLabel\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "server", 255 );
						val = hv_fetch( h, "server", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->server, SvPV_nolen(*val), sizeof(p->server) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"server\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "valueField", 255 );
						val = hv_fetch( h, "valueField", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->valueField = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueField\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schema", 255 );
						val = hv_fetch( h, "schema", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->schema, SvPV_nolen(*val), sizeof(p->schema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schema\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuQueryStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuQueryStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuQueryStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuQueryStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharMenuSQLStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuSQLStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuSQLStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharMenuSQLStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "labelIndex", 255 );
						val = hv_fetch( h, "labelIndex", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								copyIntArray( AR_MAX_LEVELS_DYNAMIC_MENU, p->labelIndex, *val );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"labelIndex\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "sqlCommand", 255 );
						val = hv_fetch( h, "sqlCommand", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->sqlCommand = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sqlCommand\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "server", 255 );
						val = hv_fetch( h, "server", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->server, SvPV_nolen(*val), sizeof(p->server) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"server\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "valueIndex", 255 );
						val = hv_fetch( h, "valueIndex", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->valueIndex = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueIndex\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuSQLStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuSQLStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuSQLStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuSQLStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCharMenuSSStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuSSStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuSSStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCharMenuSSStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "externList", 255 );
						val = hv_fetch( h, "externList", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARQualifierList( ctrl, h, k, &(p->externList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"externList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "server", 255 );
						val = hv_fetch( h, "server", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->server = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"server\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "parameterList", 255 );
						val = hv_fetch( h, "parameterList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldValueList( ctrl, h, k, &(p->parameterList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"parameterList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schema", 255 );
						val = hv_fetch( h, "schema", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->schema = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schema\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "menuName", 255 );
						val = hv_fetch( h, "menuName", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->menuName, SvPV_nolen(*val), sizeof(p->menuName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"menuName\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "keywordList", 255 );
						val = hv_fetch( h, "keywordList", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldValueList( ctrl, h, k, &(p->keywordList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"keywordList\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuSSStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuSSStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCharMenuSSStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCharMenuSSStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCloseWndStruct( ARControlStruct *ctrl, HV *h, char *k, ARCloseWndStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCloseWndStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCloseWndStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "closeAll", 255 );
						val = hv_fetch( h, "closeAll", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"true") ){
									p->closeAll = TRUE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"false") ){
									p->closeAll = FALSE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARCloseWndStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"closeAll\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCloseWndStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCloseWndStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCloseWndStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCloseWndStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARColumnLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARColumnLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARColumnLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARColumnLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "parent", 255 );
						val = hv_fetch( h, "parent", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->parent = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"parent\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "dataSource", 255 );
						val = hv_fetch( h, "dataSource", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->dataSource = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"dataSource\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "colLength", 255 );
						val = hv_fetch( h, "colLength", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->colLength = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"colLength\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "dataField", 255 );
						val = hv_fetch( h, "dataField", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->dataField = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"dataField\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARColumnLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARColumnLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARColumnLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARColumnLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCommitChangesStruct( ARControlStruct *ctrl, HV *h, char *k, ARCommitChangesStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCommitChangesStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCommitChangesStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "schemaName", 255 );
						val = hv_fetch( h, "schemaName", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->schemaName, SvPV_nolen(*val), sizeof(p->schemaName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schemaName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCommitChangesStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCommitChangesStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCommitChangesStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCommitChangesStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCompoundSchema( ARControlStruct *ctrl, HV *h, char *k, ARCompoundSchema *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchema: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCompoundSchema: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchema: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
						hval = hv_fetch( h, "schemaType", 10, 0 );
				
							if( hval && *hval ){
								pcase = SvPV_nolen(*hval);
								if( 0 ){
				
								}else if( !strcmp(pcase,"dialog") ){
									p->schemaType = AR_SCHEMA_DIALOG;                 
				
				
								}else if( !strcmp(pcase,"join") ){
									p->schemaType = AR_SCHEMA_JOIN;                 
				
				
								}else if( !strcmp(pcase,"regular") ){
									p->schemaType = AR_SCHEMA_REGULAR;                 
				
				#if AR_CURRENT_API_VERSION >= 8
								}else if( !strcmp(pcase,"vendor") ){
									p->schemaType = AR_SCHEMA_VENDOR;                 
				#endif
				
								}else if( !strcmp(pcase,"view") ){
									p->schemaType = AR_SCHEMA_VIEW;                 
				
								}else{
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCompoundSchema: key doesn't exist");
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, pcase );
									return -2;
								}
							}else{
								ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCompoundSchema: hv_fetch (hval) returned null");
								return -2;
							}
				
				
							switch( p->schemaType ){
				#if AR_CURRENT_API_VERSION >= 8
							case AR_SCHEMA_VENDOR:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "vendor", 255 );
										val = hv_fetch( h, "vendor", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARVendorSchema( ctrl, h, k, &(p->u.vendor) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"vendor\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchema: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_SCHEMA_VIEW:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "view", 255 );
										val = hv_fetch( h, "view", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARViewSchema( ctrl, h, k, &(p->u.view) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"view\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchema: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_SCHEMA_JOIN:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "join", 255 );
										val = hv_fetch( h, "join", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARJoinSchema( ctrl, h, k, &(p->u.join) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"join\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchema: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							case AR_SCHEMA_REGULAR:
								break;
							case AR_SCHEMA_DIALOG:
								break;
							default:
								sprintf( errText, "rev_ARCompoundSchema: invalid switch value %d", p->schemaType );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCompoundSchema: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCompoundSchema: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchema: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARCompoundSchemaList( ARControlStruct *ctrl, HV *h, char *k, ARCompoundSchemaList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchemaList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCompoundSchemaList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->compoundSchema = (ARCompoundSchema*) MALLOCNN( sizeof(ARCompoundSchema) * num );
							/* if( p->compoundSchema == NULL ){
								croak( "rev_ARCompoundSchemaList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARCompoundSchema( ctrl, h, k, &(p->compoundSchema[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchemaList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchemaList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCompoundSchemaList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCompoundSchemaList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCompoundSchemaList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARContainerOwnerObj( ARControlStruct *ctrl, HV *h, char *k, ARContainerOwnerObj *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARContainerOwnerObj: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARContainerOwnerObj: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "ownerName", 255 );
						val = hv_fetch( h, "ownerName", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->ownerName, SvPV_nolen(*val), sizeof(p->ownerName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"ownerName\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "type", 255 );
						val = hv_fetch( h, "type", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"schema") ){
									p->type = ARCONOWNER_SCHEMA;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"all") ){
									p->type = ARCONOWNER_ALL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"none") ){
									p->type = ARCONOWNER_NONE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARContainerOwnerObj: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"type\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARContainerOwnerObj: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARContainerOwnerObj: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARContainerOwnerObj: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARContainerOwnerObj: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARContainerOwnerObjList( ARControlStruct *ctrl, HV *h, char *k, ARContainerOwnerObjList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARContainerOwnerObjList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARContainerOwnerObjList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->ownerObjList = (ARContainerOwnerObj*) MALLOCNN( sizeof(ARContainerOwnerObj) * num );
							/* if( p->ownerObjList == NULL ){
								croak( "rev_ARContainerOwnerObjList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARContainerOwnerObj( ctrl, h, k, &(p->ownerObjList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARContainerOwnerObjList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARContainerOwnerObjList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARContainerOwnerObjList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARContainerOwnerObjList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARContainerOwnerObjList: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 9
int
rev_ARCurrencyDetailList( ARControlStruct *ctrl, HV *h, char *k, ARCurrencyDetailList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyDetailList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCurrencyDetailList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->currencyDetailList = (ARCurrencyDetailStruct*) MALLOCNN( sizeof(ARCurrencyDetailStruct) * num );
							/* if( p->currencyDetailList == NULL ){
								croak( "rev_ARCurrencyDetailList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARCurrencyDetailStruct( ctrl, h, k, &(p->currencyDetailList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyDetailList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyDetailList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCurrencyDetailList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCurrencyDetailList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyDetailList: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 9
int
rev_ARCurrencyDetailStruct( ARControlStruct *ctrl, HV *h, char *k, ARCurrencyDetailStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyDetailStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCurrencyDetailStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "currencyCode", 255 );
						val = hv_fetch( h, "currencyCode", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->currencyCode, SvPV_nolen(*val), sizeof(p->currencyCode) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"currencyCode\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "precision", 255 );
						val = hv_fetch( h, "precision", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->precision = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"precision\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyDetailStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCurrencyDetailStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCurrencyDetailStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyDetailStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 9
int
rev_ARCurrencyLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARCurrencyLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCurrencyLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "rangeHigh", 255 );
						val = hv_fetch( h, "rangeHigh", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->rangeHigh = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"rangeHigh\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "functionalCurrencies", 255 );
						val = hv_fetch( h, "functionalCurrencies", 20, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARCurrencyDetailList( ctrl, h, k, &(p->functionalCurrencies) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"functionalCurrencies\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "allowableCurrencies", 255 );
						val = hv_fetch( h, "allowableCurrencies", 19, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARCurrencyDetailList( ctrl, h, k, &(p->allowableCurrencies) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"allowableCurrencies\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "precision", 255 );
						val = hv_fetch( h, "precision", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->precision = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"precision\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "rangeLow", 255 );
						val = hv_fetch( h, "rangeLow", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->rangeLow = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"rangeLow\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCurrencyLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCurrencyLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 9
int
rev_ARCurrencyPartStruct( ARControlStruct *ctrl, HV *h, char *k, ARCurrencyPartStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyPartStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARCurrencyPartStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "currencyCode", 255 );
						val = hv_fetch( h, "currencyCode", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->currencyCode, SvPV_nolen(*val), sizeof(p->currencyCode) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"currencyCode\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "partTag", 255 );
						val = hv_fetch( h, "partTag", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->partTag = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"partTag\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fieldId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyPartStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCurrencyPartStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARCurrencyPartStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARCurrencyPartStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARDDEStruct( ARControlStruct *ctrl, HV *h, char *k, ARDDEStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDDEStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARDDEStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "topic", 255 );
						val = hv_fetch( h, "topic", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->topic = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"topic\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "item", 255 );
						val = hv_fetch( h, "item", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->item = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"item\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "action", 255 );
						val = hv_fetch( h, "action", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->action = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"action\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "serviceName", 255 );
						val = hv_fetch( h, "serviceName", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->serviceName = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"serviceName\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "command", 255 );
						val = hv_fetch( h, "command", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->command = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"command\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "pathToProgram", 255 );
						val = hv_fetch( h, "pathToProgram", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->pathToProgram = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"pathToProgram\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDDEStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDDEStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDDEStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDDEStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 9
int
rev_ARDateLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARDateLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDateLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARDateLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "minDate", 255 );
						val = hv_fetch( h, "minDate", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->minDate = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"minDate\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "maxDate", 255 );
						val = hv_fetch( h, "maxDate", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->maxDate = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"maxDate\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDateLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDateLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDateLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDateLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARDayStruct( ARControlStruct *ctrl, HV *h, char *k, ARDayStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDayStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARDayStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "weekday", 255 );
						val = hv_fetch( h, "weekday", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->weekday = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"weekday\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "minute", 255 );
						val = hv_fetch( h, "minute", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->minute = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"minute\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "hourmask", 255 );
						val = hv_fetch( h, "hourmask", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->hourmask = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"hourmask\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "monthday", 255 );
						val = hv_fetch( h, "monthday", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->monthday = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"monthday\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDayStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDayStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDayStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDayStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARDecimalLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARDecimalLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDecimalLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARDecimalLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "rangeHigh", 255 );
						val = hv_fetch( h, "rangeHigh", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->rangeHigh = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"rangeHigh\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "precision", 255 );
						val = hv_fetch( h, "precision", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->precision = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"precision\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "rangeLow", 255 );
						val = hv_fetch( h, "rangeLow", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->rangeLow = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"rangeLow\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDecimalLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDecimalLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDecimalLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDecimalLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARDiaryLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARDiaryLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDiaryLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARDiaryLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "fullTextOptions", 255 );
						val = hv_fetch( h, "fullTextOptions", 15, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"indexed") ){
									p->fullTextOptions = AR_FULLTEXT_OPTIONS_INDEXED;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"none") ){
									p->fullTextOptions = AR_FULLTEXT_OPTIONS_NONE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARDiaryLimitsStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fullTextOptions\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDiaryLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDiaryLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDiaryLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDiaryLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 8
int
rev_ARDisplayLimits( ARControlStruct *ctrl, HV *h, char *k, ARDisplayLimits *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDisplayLimits: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARDisplayLimits: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				#if AR_CURRENT_API_VERSION >= 14
					{
						SV **val;
						strncpy( k, "lengthUnits", 255 );
						val = hv_fetch( h, "lengthUnits", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"char") ){
									p->lengthUnits = AR_LENGTH_UNIT_CHAR;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"byte") ){
									p->lengthUnits = AR_LENGTH_UNIT_BYTE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARDisplayLimits: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"lengthUnits\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "maxLength", 255 );
						val = hv_fetch( h, "maxLength", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->maxLength = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"maxLength\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDisplayLimits: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDisplayLimits: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARDisplayLimits: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARDisplayLimits: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_AREntryIdList( ARControlStruct *ctrl, HV *h, char *k, AREntryIdList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryIdList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREntryIdList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->entryIdList = (AREntryIdType*) MALLOCNN( sizeof(AREntryIdType) * num );
							/* if( p->entryIdList == NULL ){
								croak( "rev_AREntryIdList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									strncpy( p->entryIdList[i], SvPV_nolen(*item), sizeof(p->entryIdList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryIdList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryIdList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryIdList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryIdList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryIdList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_AREntryListFieldList( ARControlStruct *ctrl, HV *h, char *k, AREntryListFieldList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREntryListFieldList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->fieldsList = (AREntryListFieldStruct*) MALLOCNN( sizeof(AREntryListFieldStruct) * num );
							/* if( p->fieldsList == NULL ){
								croak( "rev_AREntryListFieldList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_AREntryListFieldStruct( ctrl, h, k, &(p->fieldsList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryListFieldList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryListFieldList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_AREntryListFieldStruct( ARControlStruct *ctrl, HV *h, char *k, AREntryListFieldStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREntryListFieldStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "separator", 255 );
						val = hv_fetch( h, "separator", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->separator, SvPV_nolen(*val), sizeof(p->separator) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"separator\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "columnWidth", 255 );
						val = hv_fetch( h, "columnWidth", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->columnWidth = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"columnWidth\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fieldId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryListFieldStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryListFieldStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_AREntryListFieldValueList( ARControlStruct *ctrl, HV *h, char *k, AREntryListFieldValueList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldValueList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREntryListFieldValueList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->entryList = (AREntryListFieldValueStruct*) MALLOCNN( sizeof(AREntryListFieldValueStruct) * num );
							/* if( p->entryList == NULL ){
								croak( "rev_AREntryListFieldValueList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_AREntryListFieldValueStruct( ctrl, h, k, &(p->entryList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldValueList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldValueList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryListFieldValueList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryListFieldValueList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldValueList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_AREntryListFieldValueStruct( ARControlStruct *ctrl, HV *h, char *k, AREntryListFieldValueStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldValueStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREntryListFieldValueStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "entryId", 255 );
						val = hv_fetch( h, "entryId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_AREntryIdList( ctrl, h, k, &(p->entryId) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"entryId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "entryValues", 255 );
						val = hv_fetch( h, "entryValues", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->entryValues = MALLOCNN(sizeof(ARFieldValueList)); rev_ARFieldValueList( ctrl, h, k, p->entryValues );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"entryValues\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldValueStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryListFieldValueStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryListFieldValueStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryListFieldValueStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 11
int
rev_AREntryReturn( ARControlStruct *ctrl, HV *h, char *k, AREntryReturn *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryReturn: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREntryReturn: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "entryId", 255 );
						val = hv_fetch( h, "entryId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->entryId, SvPV_nolen(*val), sizeof(p->entryId) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"entryId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "status", 255 );
						val = hv_fetch( h, "status", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARStatusList( ctrl, h, k, &(p->status) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"status\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryReturn: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryReturn: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREntryReturn: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREntryReturn: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 8
int
rev_AREnumItemList( ARControlStruct *ctrl, HV *h, char *k, AREnumItemList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumItemList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREnumItemList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->enumItemList = (AREnumItemStruct*) MALLOCNN( sizeof(AREnumItemStruct) * num );
							/* if( p->enumItemList == NULL ){
								croak( "rev_AREnumItemList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_AREnumItemStruct( ctrl, h, k, &(p->enumItemList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumItemList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumItemList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREnumItemList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREnumItemList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumItemList: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 8
int
rev_AREnumItemStruct( ARControlStruct *ctrl, HV *h, char *k, AREnumItemStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumItemStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREnumItemStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "itemNumber", 255 );
						val = hv_fetch( h, "itemNumber", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->itemNumber = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"itemNumber\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "itemName", 255 );
						val = hv_fetch( h, "itemName", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->itemName, SvPV_nolen(*val), sizeof(p->itemName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"itemName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumItemStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREnumItemStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREnumItemStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumItemStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 8
int
rev_AREnumLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, AREnumLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREnumLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "enumLimits", 255 );
						val = hv_fetch( h, "enumLimits", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
							
								{
									char *pcase = NULL;
									char errText[512];
							
									HV *h;
									SV **hval = NULL;
									char *k   = NULL;
									if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: not a hash value" );
										return -1;
									}
									h = (HV* ) SvRV((SV*) *val);
							
										if( 0 ){
							
										}else if( hv_exists(h,"queryList",9) ){
											p->listStyle = AR_ENUM_STYLE_QUERY;
											k = "queryList";
							
							
										}else if( hv_exists(h,"customList",10) ){
											p->listStyle = AR_ENUM_STYLE_CUSTOM;
											k = "customList";
							
							
										}else if( hv_exists(h,"regularList",11) ){
											p->listStyle = AR_ENUM_STYLE_REGULAR;
											k = "regularList";
							
										}else{
										    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: map error" );
										}
							
							
										switch( p->listStyle ){
							
										case AR_ENUM_STYLE_QUERY:
											{
											
											
												if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
													int i = 0, num = 0;
													HV *h = (HV* ) SvRV((SV*) *val);
													char k[256];
													k[255] = '\0';
											
											
												{
													SV **val;
													strncpy( k, "queryList", 255 );
													val = hv_fetch( h, "queryList", 9, 0 );
													if( val && *val && SvOK(*val) ){
														{
															rev_AREnumQueryStruct( ctrl, h, k, &(p->u.queryList) );
														}
													}else{
														ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryList\"" );
														return -1;
													}
												}
											
											
												}else{
													ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: hash value is not a hash reference" );
													return -1;
												}
											
											
											}
											break;
							
							
										case AR_ENUM_STYLE_CUSTOM:
											{
											
											
												if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
													int i = 0, num = 0;
													HV *h = (HV* ) SvRV((SV*) *val);
													char k[256];
													k[255] = '\0';
											
											
												{
													SV **val;
													strncpy( k, "customList", 255 );
													val = hv_fetch( h, "customList", 10, 0 );
													if( val && *val && SvOK(*val) ){
														{
															rev_AREnumItemList( ctrl, h, k, &(p->u.customList) );
														}
													}else{
														ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"customList\"" );
														return -1;
													}
												}
											
											
												}else{
													ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: hash value is not a hash reference" );
													return -1;
												}
											
											
											}
											break;
							
							
										case AR_ENUM_STYLE_REGULAR:
											{
											
											
												if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
													int i = 0, num = 0;
													HV *h = (HV* ) SvRV((SV*) *val);
													char k[256];
													k[255] = '\0';
											
											
												{
													SV **val;
													strncpy( k, "regularList", 255 );
													val = hv_fetch( h, "regularList", 11, 0 );
													if( val && *val && SvOK(*val) ){
														{
															rev_ARNameList( ctrl, h, k, &(p->u.regularList) );
														}
													}else{
														ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"regularList\"" );
														return -1;
													}
												}
											
											
												}else{
													ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: hash value is not a hash reference" );
													return -1;
												}
											
											
											}
											break;
							
										default:
											sprintf( errText, "rev_AREnumLimitsStruct: invalid switch value %d", p->listStyle );
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
										}
							
								}
							
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"enumLimits\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 8
int
rev_AREnumQueryStruct( ARControlStruct *ctrl, HV *h, char *k, AREnumQueryStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumQueryStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREnumQueryStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "numberField", 255 );
						val = hv_fetch( h, "numberField", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->numberField = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"numberField\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "nameField", 255 );
						val = hv_fetch( h, "nameField", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->nameField = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"nameField\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "qualifier", 255 );
						val = hv_fetch( h, "qualifier", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARQualifierStruct( ctrl, h, k, &(p->qualifier) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"qualifier\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "server", 255 );
						val = hv_fetch( h, "server", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->server, SvPV_nolen(*val), sizeof(p->server) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"server\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schema", 255 );
						val = hv_fetch( h, "schema", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->schema, SvPV_nolen(*val), sizeof(p->schema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schema\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumQueryStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREnumQueryStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREnumQueryStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREnumQueryStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_AREscalationTmStruct( ARControlStruct *ctrl, HV *h, char *k, AREscalationTmStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREscalationTmStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AREscalationTmStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREscalationTmStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				
							}else if( hv_exists(h,"exitGuide",9) ){
								p->escalationTmType = AR_ESCALATION_TYPE_TIMEMARK;
								k = "exitGuide";
				
				
							}else if( hv_exists(h,"exitGuide",9) ){
								p->escalationTmType = AR_ESCALATION_TYPE_INTERVAL;
								k = "exitGuide";
				
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREscalationTmStruct: map error" );
							}
				
				
							switch( p->escalationTmType ){
				
							case AR_ESCALATION_TYPE_TIMEMARK:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "exitGuide", 255 );
										val = hv_fetch( h, "exitGuide", 9, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARDayStruct( ctrl, h, k, &(p->u.date) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"exitGuide\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREscalationTmStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_ESCALATION_TYPE_INTERVAL:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "exitGuide", 255 );
										val = hv_fetch( h, "exitGuide", 9, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.interval = SvIV(*val);
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"exitGuide\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREscalationTmStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							default:
								sprintf( errText, "rev_AREscalationTmStruct: invalid switch value %d", p->escalationTmType );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREscalationTmStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AREscalationTmStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AREscalationTmStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARExitGuideStruct( ARControlStruct *ctrl, HV *h, char *k, ARExitGuideStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARExitGuideStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARExitGuideStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "closeAll", 255 );
						val = hv_fetch( h, "closeAll", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"true") ){
									p->closeAll = TRUE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"false") ){
									p->closeAll = FALSE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARExitGuideStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"closeAll\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARExitGuideStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARExitGuideStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARExitGuideStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARExitGuideStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFieldLimitList( ARControlStruct *ctrl, HV *h, char *k, ARFieldLimitList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldLimitList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFieldLimitList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->fieldLimitList = (ARFieldLimitStruct*) MALLOCNN( sizeof(ARFieldLimitStruct) * num );
							/* if( p->fieldLimitList == NULL ){
								croak( "rev_ARFieldLimitList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARFieldLimitStruct( ctrl, h, k, &(p->fieldLimitList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldLimitList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldLimitList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldLimitList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldLimitList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldLimitList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFieldLimitStruct( ARControlStruct *ctrl, HV *h, char *k, ARFieldLimitStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldLimitStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFieldLimitStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
							// pcase = SvPV_nolen(*val);
							// p->dataType = caseLookUpTypeNumber( (TypeMapStruct*) dataType, pcase );
							HV *h2 = (HV* ) SvRV((SV*) *val);
							SV** val = hv_fetch( h2, "dataType", 8, 0 );
							p->dataType = SvIV(*val);
				
				
							switch( p->dataType ){
				
							case AR_DATA_TYPE_DIARY:
								{
									rev_ARDiaryLimitsStruct( ctrl, h, k, &(p->u.diaryLimits) );
								}
								break;
				
				#if AR_CURRENT_API_VERSION >= 8
							case AR_DATA_TYPE_VIEW:
								{
									rev_ARViewLimits( ctrl, h, k, &(p->u.viewLimits) );
								}
								break;
				#endif
				
							case AR_DATA_TYPE_INTEGER:
								{
									rev_ARIntegerLimitsStruct( ctrl, h, k, &(p->u.intLimits) );
								}
								break;
				
				
							case AR_DATA_TYPE_CHAR:
								{
									rev_ARCharLimitsStruct( ctrl, h, k, &(p->u.charLimits) );
								}
								break;
				
				#if AR_CURRENT_API_VERSION >= 9
							case AR_DATA_TYPE_DATE:
								{
									rev_ARDateLimitsStruct( ctrl, h, k, &(p->u.dateLimits) );
								}
								break;
				#endif
				#if AR_CURRENT_API_VERSION >= 8
							case AR_DATA_TYPE_ENUM:
								{
									rev_AREnumLimitsStruct( ctrl, h, k, &(p->u.enumLimits) );
								}
								break;
				#endif
				#if AR_CURRENT_API_VERSION >= 9
							case AR_DATA_TYPE_CURRENCY:
								{
									rev_ARCurrencyLimitsStruct( ctrl, h, k, &(p->u.currencyLimits) );
								}
								break;
				#endif
				
							case AR_DATA_TYPE_COLUMN:
								{
									rev_ARColumnLimitsStruct( ctrl, h, k, &(p->u.columnLimits) );
								}
								break;
				
				
							case AR_DATA_TYPE_ATTACH:
								{
									rev_ARAttachLimitsStruct( ctrl, h, k, &(p->u.attachLimits) );
								}
								break;
				
				#if AR_CURRENT_API_VERSION >= 8
							case AR_DATA_TYPE_DISPLAY:
								{
									rev_ARDisplayLimits( ctrl, h, k, &(p->u.displayLimits) );
								}
								break;
				#endif
				
							case AR_DATA_TYPE_TABLE:
								{
									rev_ARTableLimitsStruct( ctrl, h, k, &(p->u.tableLimits) );
								}
								break;
				
				
							case AR_DATA_TYPE_DECIMAL:
								{
									rev_ARDecimalLimitsStruct( ctrl, h, k, &(p->u.decimalLimits) );
								}
								break;
				
				
							case AR_DATA_TYPE_REAL:
								{
									rev_ARRealLimitsStruct( ctrl, h, k, &(p->u.realLimits) );
								}
								break;
				
							default:
								sprintf( errText, "rev_ARFieldLimitStruct: invalid switch value %d", p->dataType );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldLimitStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldLimitStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldLimitStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFieldMappingList( ARControlStruct *ctrl, HV *h, char *k, ARFieldMappingList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFieldMappingList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->mappingList = (ARFieldMappingStruct*) MALLOCNN( sizeof(ARFieldMappingStruct) * num );
							/* if( p->mappingList == NULL ){
								croak( "rev_ARFieldMappingList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARFieldMappingStruct( ctrl, h, k, &(p->mappingList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldMappingList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldMappingList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFieldMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARFieldMappingStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFieldMappingStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
						hval = hv_fetch( h, "fieldType", 9, 0 );
				
							if( hval && *hval ){
								pcase = SvPV_nolen(*hval);
								if( 0 ){
				#if AR_CURRENT_API_VERSION >= 10
								}else if( SvIV(*hval) == 5 ){
									p->fieldType = AR_FIELD_INHERITANCE;                 
				#endif
				
								}else if( SvIV(*hval) == 2 ){
									p->fieldType = AR_FIELD_JOIN;                 
				
				
								}else if( SvIV(*hval) == 0 ){
									p->fieldType = AR_FIELD_NONE;                 
				
				
								}else if( SvIV(*hval) == 1 ){
									p->fieldType = AR_FIELD_REGULAR;                 
				
				#if AR_CURRENT_API_VERSION >= 8
								}else if( SvIV(*hval) == 4 ){
									p->fieldType = AR_FIELD_VENDOR;                 
				#endif
				
								}else if( SvIV(*hval) == 3 ){
									p->fieldType = AR_FIELD_VIEW;                 
				
								}else{
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: key doesn't exist");
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, pcase );
									return -2;
								}
							}else{
								ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: hv_fetch (hval) returned null");
								return -2;
							}
				
				
							switch( p->fieldType ){
				#if AR_CURRENT_API_VERSION >= 8
							case AR_FIELD_VENDOR:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "vendor", 255 );
										val = hv_fetch( h, "vendor", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARVendorMappingStruct( ctrl, h, k, &(p->u.vendor) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"vendor\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				#if AR_CURRENT_API_VERSION >= 10
							case AR_FIELD_INHERITANCE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "inheritance", 255 );
										val = hv_fetch( h, "inheritance", 11, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARInheritanceMappingStruct( ctrl, h, k, &(p->u.inheritance) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"inheritance\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_FIELD_VIEW:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "view", 255 );
										val = hv_fetch( h, "view", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARViewMappingStruct( ctrl, h, k, &(p->u.view) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"view\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FIELD_JOIN:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "join", 255 );
										val = hv_fetch( h, "join", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARJoinMappingStruct( ctrl, h, k, &(p->u.join) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"join\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							case AR_FIELD_REGULAR:
								break;
							case AR_FIELD_NONE:
								break;
							default:
								sprintf( errText, "rev_ARFieldMappingStruct: invalid switch value %d", p->fieldType );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldMappingStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFieldValueList( ARControlStruct *ctrl, HV *h, char *k, ARFieldValueList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFieldValueList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->fieldValueList = (ARFieldValueStruct*) MALLOCNN( sizeof(ARFieldValueStruct) * num );
							/* if( p->fieldValueList == NULL ){
								croak( "rev_ARFieldValueList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARFieldValueStruct( ctrl, h, k, &(p->fieldValueList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldValueList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldValueList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFieldValueOrArithStruct( ARControlStruct *ctrl, HV *h, char *k, ARFieldValueOrArithStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFieldValueOrArithStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				#if AR_CURRENT_API_VERSION >= 9
							}else if( hv_exists(h,"currencyField",13) ){
								p->tag = AR_CURRENCY_FLD;
								k = "currencyField";
				#endif
				
							}else if( hv_exists(h,"queryCurrent",12) ){
								p->tag = AR_FIELD_CURRENT;
								k = "queryCurrent";
				
				
							}else if( hv_exists(h,"value",5) ){
								p->tag = AR_VALUE;
								k = "value";
				
				
							}else if( hv_exists(h,"fieldId",7) ){
								p->tag = AR_FIELD;
								k = "fieldId";
				
				
							}else if( hv_exists(h,"TR_fieldId",10) ){
								p->tag = AR_FIELD_TRAN;
								k = "TR_fieldId";
				
				
							}else if( hv_exists(h,"queryValue",10) ){
								p->tag = AR_QUERY;
								k = "queryValue";
				
				
							}else if( hv_exists(h,"statHistory",11) ){
								p->tag = AR_STAT_HISTORY;
								k = "statHistory";
				
				
							}else if( hv_exists(h,"arith",5) ){
								p->tag = AR_ARITHMETIC;
								k = "arith";
				
				
							}else if( hv_exists(h,"valueSet",8) ){
								p->tag = AR_VALUE_SET;
								k = "valueSet";
				
				
							}else if( hv_exists(h,"variable",8) ){
								p->tag = AR_LOCAL_VARIABLE;
								k = "variable";
				
				
							}else if( hv_exists(h,"DB_fieldId",10) ){
								p->tag = AR_FIELD_DB;
								k = "DB_fieldId";
				
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: map error" );
							}
				
				
							switch( p->tag ){
				#if AR_CURRENT_API_VERSION >= 9
							case AR_CURRENCY_FLD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "currencyField", 255 );
										val = hv_fetch( h, "currencyField", 13, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.currencyField = MALLOCNN(sizeof(ARCurrencyPartStruct)); rev_ARCurrencyPartStruct( ctrl, h, k, p->u.currencyField );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"currencyField\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_FIELD_CURRENT:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "queryCurrent", 255 );
										val = hv_fetch( h, "queryCurrent", 12, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.fieldId = SvIV(*val);
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryCurrent\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_VALUE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "value", 255 );
										val = hv_fetch( h, "value", 5, 0 );
										if( val && *val && (SvOK(*val) || SvTYPE(*val) == SVt_NULL) ){
											{
												rev_ARValueStruct( ctrl, h, k, "dataType", &(p->u.value) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"value\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FIELD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldId", 255 );
										val = hv_fetch( h, "fieldId", 7, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.fieldId = SvIV(*val);
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FIELD_TRAN:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "TR_fieldId", 255 );
										val = hv_fetch( h, "TR_fieldId", 10, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.fieldId = SvIV(*val);
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"TR_fieldId\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_QUERY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "queryValue", 255 );
										val = hv_fetch( h, "queryValue", 10, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.queryValue = MALLOCNN(sizeof(ARQueryValueStruct)); rev_ARQueryValueStruct( ctrl, h, k, p->u.queryValue );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryValue\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_STAT_HISTORY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "statHistory", 255 );
										val = hv_fetch( h, "statHistory", 11, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARStatHistoryValue( ctrl, h, k, &(p->u.statHistory) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"statHistory\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_ARITHMETIC:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "arith", 255 );
										val = hv_fetch( h, "arith", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.arithOp = MALLOCNN(sizeof(ARArithOpStruct)); rev_ARArithOpStruct( ctrl, h, k, p->u.arithOp );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"arith\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_VALUE_SET:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "valueSet", 255 );
										val = hv_fetch( h, "valueSet", 8, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARValueList( ctrl, h, k, &(p->u.valueSet) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueSet\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_LOCAL_VARIABLE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "variable", 255 );
										val = hv_fetch( h, "variable", 8, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.variable = SvIV(*val);
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"variable\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FIELD_DB:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "DB_fieldId", 255 );
										val = hv_fetch( h, "DB_fieldId", 10, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.fieldId = SvIV(*val);
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"DB_fieldId\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							default:
								sprintf( errText, "rev_ARFieldValueOrArithStruct: invalid switch value %d", p->tag );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueOrArithStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFieldValueStruct( ARControlStruct *ctrl, HV *h, char *k, ARFieldValueStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFieldValueStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "value", 255 );
						val = hv_fetch( h, "value", 5, 0 );
						if( val && *val && (SvOK(*val) || SvTYPE(*val) == SVt_NULL) ){
							{
								rev_ARValueStruct( ctrl, h, k, "dataType", &(p->value) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"value\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fieldId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldValueStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFieldValueStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFieldValueStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFilterActionList( ARControlStruct *ctrl, HV *h, char *k, ARFilterActionList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFilterActionList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->actionList = (ARFilterActionStruct*) MALLOCNN( sizeof(ARFilterActionStruct) * num );
							/* if( p->actionList == NULL ){
								croak( "rev_ARFilterActionList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARFilterActionStruct( ctrl, h, k, &(p->actionList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFilterActionList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFilterActionList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARFilterActionNotify( ARControlStruct *ctrl, HV *h, char *k, ARFilterActionNotify *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionNotify: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFilterActionNotify: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				#if AR_CURRENT_API_VERSION >= 9
					{
						SV **val;
						strncpy( k, "notifyAdvanced", 255 );
						val = hv_fetch( h, "notifyAdvanced", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->notifyAdvanced = MALLOCNN(sizeof(ARFilterActionNotifyAdvanced)); rev_ARFilterActionNotifyAdvanced( ctrl, h, k, p->notifyAdvanced );
							}
						}else{
							p->notifyAdvanced = NULL;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "fieldIdListType", 255 );
						val = hv_fetch( h, "fieldIdListType", 15, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fieldIdListType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldIdListType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "subjectText", 255 );
						val = hv_fetch( h, "subjectText", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->subjectText = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"subjectText\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "notifyText", 255 );
						val = hv_fetch( h, "notifyText", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->notifyText = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"notifyText\"" );
							return -1;
						}
					}
				
				#if AR_CURRENT_API_VERSION >= 9
					{
						SV **val;
						strncpy( k, "notifyBehavior", 255 );
						val = hv_fetch( h, "notifyBehavior", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->notifyBehavior = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"notifyBehavior\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "notifyMechanismXRef", 255 );
						val = hv_fetch( h, "notifyMechanismXRef", 19, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->notifyMechanismXRef = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"notifyMechanismXRef\"" );
							return -1;
						}
					}
				
				#if AR_CURRENT_API_VERSION >= 9
					{
						SV **val;
						strncpy( k, "notifyPermission", 255 );
						val = hv_fetch( h, "notifyPermission", 16, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->notifyPermission = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"notifyPermission\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "user", 255 );
						val = hv_fetch( h, "user", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->user = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"user\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "notifyPriority", 255 );
						val = hv_fetch( h, "notifyPriority", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->notifyPriority = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"notifyPriority\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "notifyMechanism", 255 );
						val = hv_fetch( h, "notifyMechanism", 15, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->notifyMechanism = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"notifyMechanism\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldList", 255 );
						val = hv_fetch( h, "fieldList", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARInternalIdList( ctrl, h, k, &(p->fieldIdList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldList\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionNotify: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFilterActionNotify: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFilterActionNotify: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionNotify: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 9
int
rev_ARFilterActionNotifyAdvanced( ARControlStruct *ctrl, HV *h, char *k, ARFilterActionNotifyAdvanced *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionNotifyAdvanced: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFilterActionNotifyAdvanced: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "replyTo", 255 );
						val = hv_fetch( h, "replyTo", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->replyTo = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"replyTo\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "bcc", 255 );
						val = hv_fetch( h, "bcc", 3, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->bcc = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"bcc\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "contentTemplate", 255 );
						val = hv_fetch( h, "contentTemplate", 15, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->contentTemplate = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"contentTemplate\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "cc", 255 );
						val = hv_fetch( h, "cc", 2, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->cc = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"cc\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "from", 255 );
						val = hv_fetch( h, "from", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->from = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"from\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "footerTemplate", 255 );
						val = hv_fetch( h, "footerTemplate", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->footerTemplate = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"footerTemplate\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "organization", 255 );
						val = hv_fetch( h, "organization", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->organization = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"organization\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "mailboxName", 255 );
						val = hv_fetch( h, "mailboxName", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->mailboxName = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"mailboxName\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "headerTemplate", 255 );
						val = hv_fetch( h, "headerTemplate", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->headerTemplate = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"headerTemplate\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionNotifyAdvanced: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFilterActionNotifyAdvanced: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFilterActionNotifyAdvanced: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionNotifyAdvanced: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARFilterActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARFilterActionStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARFilterActionStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				
							}else if( hv_exists(h,"gotoAction",10) ){
								p->action = AR_FILTER_ACTION_GOTOACTION;
								k = "gotoAction";
				
				
							}else if( hv_exists(h,"gotoGuide",9) ){
								p->action = AR_FILTER_ACTION_GOTOGUIDELABEL;
								k = "gotoGuide";
				
				
							}else if( hv_exists(h,"notify",6) ){
								p->action = AR_FILTER_ACTION_NOTIFY;
								k = "notify";
				
				#if AR_CURRENT_API_VERSION <= 9
							}else if( hv_exists(h,"assign_fields",13) ){
								p->action = AR_FILTER_ACTION_FIELDS;
								k = "assign_fields";
				#endif
				
							}else if( hv_exists(h,"log",3) ){
								p->action = AR_FILTER_ACTION_LOG;
								k = "log";
				
				
							}else if( hv_exists(h,"message",7) ){
								p->action = AR_FILTER_ACTION_MESSAGE;
								k = "message";
				
				#if AR_CURRENT_API_VERSION >= 10
							}else if( hv_exists(h,"fieldp",6) ){
								p->action = AR_FILTER_ACTION_FIELDP;
								k = "fieldp";
				#endif
				
							}else if( hv_exists(h,"exitGuide",9) ){
								p->action = AR_FILTER_ACTION_EXITGUIDE;
								k = "exitGuide";
				
				
							}else if( hv_exists(h,"process",7) ){
								p->action = AR_FILTER_ACTION_PROCESS;
								k = "process";
				
				
							}else if( hv_exists(h,"callGuide",9) ){
								p->action = AR_FILTER_ACTION_CALLGUIDE;
								k = "callGuide";
				
				#if AR_CURRENT_API_VERSION >= 10
							}else if( hv_exists(h,"assign_fields",13) ){
								p->action = AR_FILTER_ACTION_FIELDS;
								k = "assign_fields";
				#endif
				
							}else if( hv_exists(h,"sqlCommand",10) ){
								p->action = AR_FILTER_ACTION_SQL;
								k = "sqlCommand";
				
				#if AR_CURRENT_API_VERSION <= 9
							}else if( hv_exists(h,"fieldp",6) ){
								p->action = AR_FILTER_ACTION_FIELDP;
								k = "fieldp";
				#endif
							}else if( 1 ){
							    p->action = AR_FILTER_ACTION_NONE;
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: map error" );
							}
				
				
							switch( p->action ){
				
							case AR_FILTER_ACTION_GOTOACTION:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "gotoAction", 255 );
										val = hv_fetch( h, "gotoAction", 10, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARGotoActionStruct( ctrl, h, k, &(p->u.gotoAction) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"gotoAction\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FILTER_ACTION_GOTOGUIDELABEL:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "gotoGuide", 255 );
										val = hv_fetch( h, "gotoGuide", 9, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.gotoGuide.label = strdup( SvPV_nolen(*val) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"gotoGuide\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FILTER_ACTION_NOTIFY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "notify", 255 );
										val = hv_fetch( h, "notify", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARFilterActionNotify( ctrl, h, k, &(p->u.notify) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"notify\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				#if AR_CURRENT_API_VERSION <= 9
							case AR_FILTER_ACTION_FIELDS:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "assign_fields", 255 );
										val = hv_fetch( h, "assign_fields", 13, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARFieldAssignList( ctrl, h, k, &(p->u.fieldList) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"assign_fields\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_FILTER_ACTION_LOG:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "log", 255 );
										val = hv_fetch( h, "log", 3, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.logFile = strdup( SvPV_nolen(*val) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"log\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FILTER_ACTION_MESSAGE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "message", 255 );
										val = hv_fetch( h, "message", 7, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARFilterStatusStruct( ctrl, h, k, &(p->u.message) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"message\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				#if AR_CURRENT_API_VERSION >= 10
							case AR_FILTER_ACTION_FIELDP:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldp", 255 );
										val = hv_fetch( h, "fieldp", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARPushFieldsActionStruct( ctrl, h, k, &(p->u.pushFields) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldp\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_FILTER_ACTION_EXITGUIDE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "exitGuide", 255 );
										val = hv_fetch( h, "exitGuide", 9, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARExitGuideStruct( ctrl, h, k, &(p->u.exitGuide) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"exitGuide\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FILTER_ACTION_PROCESS:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "process", 255 );
										val = hv_fetch( h, "process", 7, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.process = strdup( SvPV_nolen(*val) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"process\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FILTER_ACTION_CALLGUIDE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "callGuide", 255 );
										val = hv_fetch( h, "callGuide", 9, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARCallGuideStruct( ctrl, h, k, &(p->u.callGuide) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"callGuide\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				#if AR_CURRENT_API_VERSION >= 10
							case AR_FILTER_ACTION_FIELDS:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "assign_fields", 255 );
										val = hv_fetch( h, "assign_fields", 13, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARSetFieldsActionStruct( ctrl, h, k, &(p->u.setFields) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"assign_fields\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_FILTER_ACTION_SQL:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "sqlCommand", 255 );
										val = hv_fetch( h, "sqlCommand", 10, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARSQLStruct( ctrl, h, k, &(p->u.sqlCommand) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sqlCommand\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				#if AR_CURRENT_API_VERSION <= 9
							case AR_FILTER_ACTION_FIELDP:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldp", 255 );
										val = hv_fetch( h, "fieldp", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARPushFieldsList( ctrl, h, k, &(p->u.pushFieldsList) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldp\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
							case AR_FILTER_ACTION_NONE:
								break;
							default:
								sprintf( errText, "rev_ARFilterActionStruct: invalid switch value %d", p->action );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFilterActionStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARFilterActionStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARFilterActionStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARGotoActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARGotoActionStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARGotoActionStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARGotoActionStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "fieldIdOrValue", 255 );
						val = hv_fetch( h, "fieldIdOrValue", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fieldIdOrValue = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldIdOrValue\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "tag", 255 );
						val = hv_fetch( h, "tag", 3, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->tag = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"tag\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARGotoActionStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARGotoActionStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARGotoActionStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARGotoActionStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARGotoGuideLabelStruct( ARControlStruct *ctrl, HV *h, char *k, ARGotoGuideLabelStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARGotoGuideLabelStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARGotoGuideLabelStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "label", 255 );
						val = hv_fetch( h, "label", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->label = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"label\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARGotoGuideLabelStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARGotoGuideLabelStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARGotoGuideLabelStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARGotoGuideLabelStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARIndexList( ARControlStruct *ctrl, HV *h, char *k, ARIndexList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARIndexList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->indexList = (ARIndexStruct*) MALLOCNN( sizeof(ARIndexStruct) * num );
							/* if( p->indexList == NULL ){
								croak( "rev_ARIndexList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARIndexStruct( ctrl, h, k, &(p->indexList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARIndexList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARIndexList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARIndexStruct( ARControlStruct *ctrl, HV *h, char *k, ARIndexStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARIndexStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "unique", 255 );
						val = hv_fetch( h, "unique", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->unique = (char) SvIV(*val);
							}
						}else{
							p->unique = FALSE;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldIds", 255 );
						val = hv_fetch( h, "fieldIds", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								{
									if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
										int i = 0, num = 0;
										AV *ar = (AV*) SvRV((SV*) *val);
							
										num = av_len(ar) + 1;
										p->numFields = num;
										if( num == 0 ) return 0;
							
							
										for( i = 0; i < num; ++i ){
											SV **item = av_fetch( ar, i, 0 );
							
											if( item && *item ){
												char *k = "_";
												HV *h = newHV();
												
												SvREFCNT_inc( *item );
							                    hv_store( h, k, strlen(k), *item, 0 );
							
												p->fieldIds[i] = SvIV(*item);
												hv_undef( h );
											}else{
												ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexStruct: invalid inner array value" );
											}
										}
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexStruct: hash value is not an array reference" );
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
										return -1;
									}
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldIds\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARIndexStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARIndexStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIndexStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 10
int
rev_ARInheritanceMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARInheritanceMappingStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARInheritanceMappingStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARInheritanceMappingStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "dataMappingId", 255 );
						val = hv_fetch( h, "dataMappingId", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->dataMappingId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"dataMappingId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "referenceMask", 255 );
						val = hv_fetch( h, "referenceMask", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->referenceMask = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"referenceMask\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "srcSchema", 255 );
						val = hv_fetch( h, "srcSchema", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->srcSchema, SvPV_nolen(*val), sizeof(p->srcSchema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"srcSchema\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARInheritanceMappingStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARInheritanceMappingStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARInheritanceMappingStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARInheritanceMappingStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARIntegerLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARIntegerLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIntegerLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARIntegerLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "min", 255 );
						val = hv_fetch( h, "min", 3, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->rangeLow = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"min\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "max", 255 );
						val = hv_fetch( h, "max", 3, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->rangeHigh = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"max\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIntegerLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARIntegerLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARIntegerLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARIntegerLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARJoinMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARJoinMappingStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARJoinMappingStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARJoinMappingStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "realId", 255 );
						val = hv_fetch( h, "realId", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->realId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"realId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schemaIndex", 255 );
						val = hv_fetch( h, "schemaIndex", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->schemaIndex = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schemaIndex\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARJoinMappingStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARJoinMappingStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARJoinMappingStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARJoinMappingStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARJoinSchema( ARControlStruct *ctrl, HV *h, char *k, ARJoinSchema *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARJoinSchema: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARJoinSchema: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "memberA", 255 );
						val = hv_fetch( h, "memberA", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->memberA, SvPV_nolen(*val), sizeof(p->memberA) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"memberA\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "joinQual", 255 );
						val = hv_fetch( h, "joinQual", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARQualifierStruct( ctrl, h, k, &(p->joinQual) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"joinQual\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "option", 255 );
						val = hv_fetch( h, "option", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->option = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"option\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "memberB", 255 );
						val = hv_fetch( h, "memberB", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->memberB, SvPV_nolen(*val), sizeof(p->memberB) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"memberB\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARJoinSchema: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARJoinSchema: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARJoinSchema: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARJoinSchema: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARLicenseDateStruct( ARControlStruct *ctrl, HV *h, char *k, ARLicenseDateStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARLicenseDateStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARLicenseDateStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "month", 255 );
						val = hv_fetch( h, "month", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->month = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"month\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "day", 255 );
						val = hv_fetch( h, "day", 3, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->day = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"day\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "year", 255 );
						val = hv_fetch( h, "year", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->year = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"year\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARLicenseDateStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARLicenseDateStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARLicenseDateStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARLicenseDateStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARLicenseValidStruct( ARControlStruct *ctrl, HV *h, char *k, ARLicenseValidStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARLicenseValidStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARLicenseValidStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "tokenList", 255 );
						val = hv_fetch( h, "tokenList", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->tokenList = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"tokenList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "expireDate", 255 );
						val = hv_fetch( h, "expireDate", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARLicenseDateStruct( ctrl, h, k, &(p->expireDate) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"expireDate\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "numLicenses", 255 );
						val = hv_fetch( h, "numLicenses", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->numLicenses = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"numLicenses\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "isDemo", 255 );
						val = hv_fetch( h, "isDemo", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->isDemo = (char) SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"isDemo\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARLicenseValidStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARLicenseValidStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARLicenseValidStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARLicenseValidStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 14 && AR_CURRENT_API_VERSION <= 14
int
rev_ARMultiSchemaCurrencyPartStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaCurrencyPartStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaCurrencyPartStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaCurrencyPartStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "currencyCode", 255 );
						val = hv_fetch( h, "currencyCode", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->currencyCode, SvPV_nolen(*val), sizeof(p->currencyCode) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"currencyCode\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "partTag", 255 );
						val = hv_fetch( h, "partTag", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->partTag = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"partTag\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdStruct( ctrl, h, k, &(p->fieldId) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaCurrencyPartStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaCurrencyPartStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaCurrencyPartStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaCurrencyPartStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFieldFuncList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldFuncList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFieldFuncList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->listPtr = (ARMultiSchemaFieldFuncStruct*) MALLOCNN( sizeof(ARMultiSchemaFieldFuncStruct) * num );
							/* if( p->listPtr == NULL ){
								croak( "rev_ARMultiSchemaFieldFuncList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARMultiSchemaFieldFuncStruct( ctrl, h, k, &(p->listPtr[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncList: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFieldFuncStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldFuncStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFieldFuncStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "funcId", 255 );
						val = hv_fetch( h, "funcId", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->funcId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"funcId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromAlias", 255 );
						val = hv_fetch( h, "queryFromAlias", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->queryFromAlias, SvPV_nolen(*val), sizeof(p->queryFromAlias) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromAlias\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fieldId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFieldFuncValueOrArithStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldFuncValueOrArithStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFieldFuncValueOrArithStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				#if AR_CURRENT_API_VERSION >= 9
							}else if( hv_exists(h,"currencyField",13) ){
								p->tag = AR_CURRENCY_FLD;
								k = "currencyField";
				#endif
				
							}else if( hv_exists(h,"value",5) ){
								p->tag = AR_VALUE;
								k = "value";
				
				
							}else if( hv_exists(h,"queryValue",10) ){
								p->tag = AR_VALUE_SET_QUERY;
								k = "queryValue";
				
				
							}else if( hv_exists(h,"fieldFunc",9) ){
								p->tag = AR_FIELD;
								k = "fieldFunc";
				
				
							}else if( hv_exists(h,"arith",5) ){
								p->tag = AR_ARITHMETIC;
								k = "arith";
				
				
							}else if( hv_exists(h,"valueSet",8) ){
								p->tag = AR_VALUE_SET;
								k = "valueSet";
				
				
							}else if( hv_exists(h,"statHistory",11) ){
								p->tag = AR_STAT_HISTORY;
								k = "statHistory";
				
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: map error" );
							}
				
				
							switch( p->tag ){
				#if AR_CURRENT_API_VERSION >= 9
							case AR_CURRENCY_FLD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "currencyField", 255 );
										val = hv_fetch( h, "currencyField", 13, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.currencyField = MALLOCNN(sizeof(ARMultiSchemaFuncCurrencyPartStruct)); rev_ARMultiSchemaFuncCurrencyPartStruct( ctrl, h, k, p->u.currencyField );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"currencyField\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_VALUE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "value", 255 );
										val = hv_fetch( h, "value", 5, 0 );
										if( val && *val && (SvOK(*val) || SvTYPE(*val) == SVt_NULL) ){
											{
												rev_ARValueStruct( ctrl, h, k, "dataType", &(p->u.value) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"value\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_VALUE_SET_QUERY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "queryValue", 255 );
										val = hv_fetch( h, "queryValue", 10, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.valueSetQuery = MALLOCNN(sizeof(ARMultiSchemaValueSetFuncQueryStruct)); rev_ARMultiSchemaValueSetFuncQueryStruct( ctrl, h, k, p->u.valueSetQuery );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryValue\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_FIELD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldFunc", 255 );
										val = hv_fetch( h, "fieldFunc", 9, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARMultiSchemaFieldFuncStruct( ctrl, h, k, &(p->u.fieldFunc) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldFunc\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_ARITHMETIC:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "arith", 255 );
										val = hv_fetch( h, "arith", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.arithOp = MALLOCNN(sizeof(ARMultiSchemaFuncArithOpStruct)); rev_ARMultiSchemaFuncArithOpStruct( ctrl, h, k, p->u.arithOp );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"arith\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_VALUE_SET:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "valueSet", 255 );
										val = hv_fetch( h, "valueSet", 8, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARValueList( ctrl, h, k, &(p->u.valueSet) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueSet\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_STAT_HISTORY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "statHistory", 255 );
										val = hv_fetch( h, "statHistory", 11, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARMultiSchemaFuncStatHistoryValue( ctrl, h, k, &(p->u.statHistory) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"statHistory\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							default:
								sprintf( errText, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: invalid switch value %d", p->tag );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldFuncValueOrArithStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaFieldIdList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldIdList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldIdList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFieldIdList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->listPtr = (ARMultiSchemaFieldIdStruct*) MALLOCNN( sizeof(ARMultiSchemaFieldIdStruct) * num );
							/* if( p->listPtr == NULL ){
								croak( "rev_ARMultiSchemaFieldIdList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARMultiSchemaFieldIdStruct( ctrl, h, k, &(p->listPtr[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldIdList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldIdList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldIdList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldIdList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldIdList: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaFieldValueOrArithStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldValueOrArithStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFieldValueOrArithStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				#if AR_CURRENT_API_VERSION >= 17
							}else if( hv_exists(h,"currencyField",13) ){
								p->tag = AR_CURRENCY_FLD;
								k = "currencyField";
				#endif
				
							}else if( hv_exists(h,"value",5) ){
								p->tag = AR_VALUE;
								k = "value";
				
				#if AR_CURRENT_API_VERSION >= 17
							}else if( hv_exists(h,"queryValue",10) ){
								p->tag = AR_VALUE_SET_QUERY;
								k = "queryValue";
				#endif
				
							}else if( hv_exists(h,"fieldId",7) ){
								p->tag = AR_FIELD;
								k = "fieldId";
				
				
							}else if( hv_exists(h,"arith",5) ){
								p->tag = AR_ARITHMETIC;
								k = "arith";
				
				
							}else if( hv_exists(h,"valueSet",8) ){
								p->tag = AR_VALUE_SET;
								k = "valueSet";
				
				#if AR_CURRENT_API_VERSION >= 17
							}else if( hv_exists(h,"statHistory",11) ){
								p->tag = AR_STAT_HISTORY;
								k = "statHistory";
				#endif
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: map error" );
							}
				
				
							switch( p->tag ){
				#if AR_CURRENT_API_VERSION >= 17
							case AR_CURRENCY_FLD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "currencyField", 255 );
										val = hv_fetch( h, "currencyField", 13, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.currencyField = MALLOCNN(sizeof(ARMultiSchemaFuncCurrencyPartStruct)); rev_ARMultiSchemaFuncCurrencyPartStruct( ctrl, h, k, p->u.currencyField );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"currencyField\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_VALUE:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "value", 255 );
										val = hv_fetch( h, "value", 5, 0 );
										if( val && *val && (SvOK(*val) || SvTYPE(*val) == SVt_NULL) ){
											{
												rev_ARValueStruct( ctrl, h, k, "dataType", &(p->u.value) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"value\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				#if AR_CURRENT_API_VERSION >= 17
							case AR_VALUE_SET_QUERY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "queryValue", 255 );
										val = hv_fetch( h, "queryValue", 10, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.valueSetQuery = MALLOCNN(sizeof(ARMultiSchemaValueSetFuncQueryStruct)); rev_ARMultiSchemaValueSetFuncQueryStruct( ctrl, h, k, p->u.valueSetQuery );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryValue\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
				
							case AR_FIELD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldId", 255 );
										val = hv_fetch( h, "fieldId", 7, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARMultiSchemaFieldIdStruct( ctrl, h, k, &(p->u.fieldId) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_ARITHMETIC:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "arith", 255 );
										val = hv_fetch( h, "arith", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.arithOp = MALLOCNN(sizeof(ARMultiSchemaArithOpStruct)); rev_ARMultiSchemaArithOpStruct( ctrl, h, k, p->u.arithOp );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"arith\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_VALUE_SET:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "valueSet", 255 );
										val = hv_fetch( h, "valueSet", 8, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARValueList( ctrl, h, k, &(p->u.valueSet) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueSet\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				#if AR_CURRENT_API_VERSION >= 17
							case AR_STAT_HISTORY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "statHistory", 255 );
										val = hv_fetch( h, "statHistory", 11, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARMultiSchemaFuncStatHistoryValue( ctrl, h, k, &(p->u.statHistory) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"statHistory\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				#endif
							default:
								sprintf( errText, "rev_ARMultiSchemaFieldValueOrArithStruct: invalid switch value %d", p->tag );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFieldValueOrArithStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFuncArithOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncArithOpStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncArithOpStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFuncArithOpStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "operandRight", 255 );
						val = hv_fetch( h, "operandRight", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldFuncValueOrArithStruct( ctrl, h, k, &(p->operandRight) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"operandRight\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "operandLeft", 255 );
						val = hv_fetch( h, "operandLeft", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldFuncValueOrArithStruct( ctrl, h, k, &(p->operandLeft) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"operandLeft\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "operation", 255 );
						val = hv_fetch( h, "operation", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->operation = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"operation\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncArithOpStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncArithOpStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncArithOpStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncArithOpStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFuncCurrencyPartStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncCurrencyPartStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncCurrencyPartStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFuncCurrencyPartStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "currencyCode", 255 );
						val = hv_fetch( h, "currencyCode", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->currencyCode, SvPV_nolen(*val), sizeof(p->currencyCode) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"currencyCode\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "partTag", 255 );
						val = hv_fetch( h, "partTag", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->partTag = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"partTag\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldFunc", 255 );
						val = hv_fetch( h, "fieldFunc", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldFuncStruct( ctrl, h, k, &(p->fieldFunc) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldFunc\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncCurrencyPartStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncCurrencyPartStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncCurrencyPartStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncCurrencyPartStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFuncQualifierStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncQualifierStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFuncQualifierStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
						hval = hv_fetch( h, "oper", 4, 0 );
				
							if( hval && *hval ){
								pcase = SvPV_nolen(*hval);
								if( 0 ){
				
								}else if( !strcmp(pcase,"and") ){
									p->operation = AR_COND_OP_AND;                 
				
				
								}else if( !strcmp(pcase,"external") ){
									p->operation = AR_COND_OP_FROM_FIELD;                 
				
				
								}else if( !strcmp(pcase,"not") ){
									p->operation = AR_COND_OP_NOT;                 
				
				
								}else if( !strcmp(pcase,"or") ){
									p->operation = AR_COND_OP_OR;                 
				
				
								}else if( !strcmp(pcase,"rel_op") ){
									p->operation = AR_COND_OP_REL_OP;                 
				
								}else{
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: key doesn't exist");
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, pcase );
									return -2;
								}
							}else{
								ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: hv_fetch (hval) returned null");
								return -2;
							}
				
				
							switch( p->operation ){
				
							case AR_COND_OP_AND:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "left", 255 );
										val = hv_fetch( h, "left", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandLeft = MALLOCNN(sizeof(ARMultiSchemaFuncQualifierStruct)); rev_ARMultiSchemaFuncQualifierStruct( ctrl, h, k, p->u.andor.operandLeft );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"left\"" );
											return -1;
										}
									}
								
								
									{
										SV **val;
										strncpy( k, "right", 255 );
										val = hv_fetch( h, "right", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandRight = MALLOCNN(sizeof(ARMultiSchemaFuncQualifierStruct)); rev_ARMultiSchemaFuncQualifierStruct( ctrl, h, k, p->u.andor.operandRight );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"right\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_REL_OP:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "rel_op", 255 );
										val = hv_fetch( h, "rel_op", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.relOp = MALLOCNN(sizeof(ARMultiSchemaFuncRelOpStruct)); rev_ARMultiSchemaFuncRelOpStruct( ctrl, h, k, p->u.relOp );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"rel_op\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_NOT:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "not", 255 );
										val = hv_fetch( h, "not", 3, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.notQual = MALLOCNN(sizeof(ARMultiSchemaFuncQualifierStruct)); rev_ARMultiSchemaFuncQualifierStruct( ctrl, h, k, p->u.notQual );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"not\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_FROM_FIELD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldFunc", 255 );
										val = hv_fetch( h, "fieldFunc", 9, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARMultiSchemaFieldFuncStruct( ctrl, h, k, &(p->u.fieldFunc) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldFunc\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_OR:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "left", 255 );
										val = hv_fetch( h, "left", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandLeft = MALLOCNN(sizeof(ARMultiSchemaFuncQualifierStruct)); rev_ARMultiSchemaFuncQualifierStruct( ctrl, h, k, p->u.andor.operandLeft );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"left\"" );
											return -1;
										}
									}
								
								
									{
										SV **val;
										strncpy( k, "right", 255 );
										val = hv_fetch( h, "right", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandRight = MALLOCNN(sizeof(ARMultiSchemaFuncQualifierStruct)); rev_ARMultiSchemaFuncQualifierStruct( ctrl, h, k, p->u.andor.operandRight );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"right\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							case AR_COND_OP_NONE:
								break;
							default:
								sprintf( errText, "rev_ARMultiSchemaFuncQualifierStruct: invalid switch value %d", p->operation );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQualifierStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFuncQueryFromList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncQueryFromList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFuncQueryFromList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->listPtr = (ARMultiSchemaFuncQueryFromStruct*) MALLOCNN( sizeof(ARMultiSchemaFuncQueryFromStruct) * num );
							/* if( p->listPtr == NULL ){
								croak( "rev_ARMultiSchemaFuncQueryFromList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARMultiSchemaFuncQueryFromStruct( ctrl, h, k, &(p->listPtr[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromList: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFuncQueryFromStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncQueryFromStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFuncQueryFromStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				
							}else if( hv_exists(h,"name",4) ){
								p->type = AR_MULTI_SCHEMA_SCHEMA_NAME;
								k = "name";
				
				
							}else if( hv_exists(h,"extRef",6) ){
								p->type = AR_MULTI_SCHEMA_NESTED_QUERY;
								k = "extRef";
				
				
							}else if( hv_exists(h,"extRef",6) ){
								p->type = AR_MULTI_SCHEMA_RECURSIVE_QUERY;
								k = "extRef";
				
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: map error" );
							}
				
				
							switch( p->type ){
				
							case AR_MULTI_SCHEMA_SCHEMA_NAME:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "name", 255 );
										val = hv_fetch( h, "name", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												strncpy( p->u.schemaName, SvPV_nolen(*val), sizeof(p->u.schemaName) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"name\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_MULTI_SCHEMA_NESTED_QUERY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "extRef", 255 );
										val = hv_fetch( h, "extRef", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.nestedQuery = MALLOCNN(sizeof(ARMultiSchemaNestedFuncQueryStruct)); rev_ARMultiSchemaNestedFuncQueryStruct( ctrl, h, k, p->u.nestedQuery );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"extRef\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_MULTI_SCHEMA_RECURSIVE_QUERY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "extRef", 255 );
										val = hv_fetch( h, "extRef", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.recursiveQuery = MALLOCNN(sizeof(ARMultiSchemaRecursiveFuncQueryStruct)); rev_ARMultiSchemaRecursiveFuncQueryStruct( ctrl, h, k, p->u.recursiveQuery );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"extRef\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							default:
								sprintf( errText, "rev_ARMultiSchemaFuncQueryFromStruct: invalid switch value %d", p->type );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "joinType", 255 );
						val = hv_fetch( h, "joinType", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->joinType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"joinType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "joinQual", 255 );
						val = hv_fetch( h, "joinQual", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->joinQual = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->joinQual );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"joinQual\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromAlias", 255 );
						val = hv_fetch( h, "queryFromAlias", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->queryFromAlias, SvPV_nolen(*val), sizeof(p->queryFromAlias) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromAlias\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncQueryFromStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFuncRelOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncRelOpStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncRelOpStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFuncRelOpStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "operandRight", 255 );
						val = hv_fetch( h, "operandRight", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldFuncValueOrArithStruct( ctrl, h, k, &(p->operandRight) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"operandRight\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "operandLeft", 255 );
						val = hv_fetch( h, "operandLeft", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldFuncValueOrArithStruct( ctrl, h, k, &(p->operandLeft) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"operandLeft\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "operation", 255 );
						val = hv_fetch( h, "operation", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->operation = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"operation\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncRelOpStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncRelOpStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncRelOpStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncRelOpStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaFuncStatHistoryValue( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncStatHistoryValue *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncStatHistoryValue: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaFuncStatHistoryValue: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "funcId", 255 );
						val = hv_fetch( h, "funcId", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->funcId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"funcId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "enumVal", 255 );
						val = hv_fetch( h, "enumVal", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->enumVal = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"enumVal\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromAlias", 255 );
						val = hv_fetch( h, "queryFromAlias", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->queryFromAlias, SvPV_nolen(*val), sizeof(p->queryFromAlias) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromAlias\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "userOrTime", 255 );
						val = hv_fetch( h, "userOrTime", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->userOrTime = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"userOrTime\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncStatHistoryValue: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncStatHistoryValue: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncStatHistoryValue: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaFuncStatHistoryValue: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaNestedFuncQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaNestedFuncQueryStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedFuncQueryStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaNestedFuncQueryStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "groupBy", 255 );
						val = hv_fetch( h, "groupBy", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdList( ctrl, h, k, &(p->groupBy) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"groupBy\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "qualifier", 255 );
						val = hv_fetch( h, "qualifier", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->qualifier = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->qualifier );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"qualifier\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromList", 255 );
						val = hv_fetch( h, "queryFromList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFuncQueryFromList( ctrl, h, k, &(p->queryFromList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "getListFuncs", 255 );
						val = hv_fetch( h, "getListFuncs", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldFuncList( ctrl, h, k, &(p->getListFuncs) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"getListFuncs\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "having", 255 );
						val = hv_fetch( h, "having", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->having = MALLOCNN(sizeof(ARMultiSchemaFuncQualifierStruct)); rev_ARMultiSchemaFuncQualifierStruct( ctrl, h, k, p->having );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"having\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedFuncQueryStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedFuncQueryStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedFuncQueryStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedFuncQueryStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaNestedQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaNestedQueryStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedQueryStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaNestedQueryStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "qualifier", 255 );
						val = hv_fetch( h, "qualifier", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->qualifier = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->qualifier );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"qualifier\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromList", 255 );
						val = hv_fetch( h, "queryFromList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaQueryFromList( ctrl, h, k, &(p->queryFromList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "getListFields", 255 );
						val = hv_fetch( h, "getListFields", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdList( ctrl, h, k, &(p->getListFields) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"getListFields\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedQueryStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedQueryStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedQueryStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaNestedQueryStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaQualifierStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaQualifierStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaQualifierStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
						hval = hv_fetch( h, "oper", 4, 0 );
				
							if( hval && *hval ){
								pcase = SvPV_nolen(*hval);
								if( 0 ){
				
								}else if( !strcmp(pcase,"and") ){
									p->operation = AR_COND_OP_AND;                 
				
				
								}else if( !strcmp(pcase,"external") ){
									p->operation = AR_COND_OP_FROM_FIELD;                 
				
				
								}else if( !strcmp(pcase,"not") ){
									p->operation = AR_COND_OP_NOT;                 
				
				
								}else if( !strcmp(pcase,"or") ){
									p->operation = AR_COND_OP_OR;                 
				
				
								}else if( !strcmp(pcase,"rel_op") ){
									p->operation = AR_COND_OP_REL_OP;                 
				
								}else{
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: key doesn't exist");
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, pcase );
									return -2;
								}
							}else{
								ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: hv_fetch (hval) returned null");
								return -2;
							}
				
				
							switch( p->operation ){
				
							case AR_COND_OP_AND:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "left", 255 );
										val = hv_fetch( h, "left", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandLeft = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->u.andor.operandLeft );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"left\"" );
											return -1;
										}
									}
								
								
									{
										SV **val;
										strncpy( k, "right", 255 );
										val = hv_fetch( h, "right", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandRight = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->u.andor.operandRight );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"right\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_REL_OP:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "rel_op", 255 );
										val = hv_fetch( h, "rel_op", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.relOp = MALLOCNN(sizeof(ARMultiSchemaRelOpStruct)); rev_ARMultiSchemaRelOpStruct( ctrl, h, k, p->u.relOp );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"rel_op\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_NOT:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "not", 255 );
										val = hv_fetch( h, "not", 3, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.notQual = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->u.notQual );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"not\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_FROM_FIELD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldId", 255 );
										val = hv_fetch( h, "fieldId", 7, 0 );
										if( val && *val && SvOK(*val) ){
											{
												rev_ARMultiSchemaFieldIdStruct( ctrl, h, k, &(p->u.fieldId) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_OR:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "left", 255 );
										val = hv_fetch( h, "left", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandLeft = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->u.andor.operandLeft );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"left\"" );
											return -1;
										}
									}
								
								
									{
										SV **val;
										strncpy( k, "right", 255 );
										val = hv_fetch( h, "right", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandRight = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->u.andor.operandRight );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"right\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							case AR_COND_OP_NONE:
								break;
							default:
								sprintf( errText, "rev_ARMultiSchemaQualifierStruct: invalid switch value %d", p->operation );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQualifierStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaQueryFromList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaQueryFromList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaQueryFromList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->listPtr = (ARMultiSchemaQueryFromStruct*) MALLOCNN( sizeof(ARMultiSchemaQueryFromStruct) * num );
							/* if( p->listPtr == NULL ){
								croak( "rev_ARMultiSchemaQueryFromList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARMultiSchemaQueryFromStruct( ctrl, h, k, &(p->listPtr[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromList: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaQueryFromStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaQueryFromStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaQueryFromStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
							if( 0 ){
				
							}else if( hv_exists(h,"schemaName",10) ){
								p->type = AR_MULTI_SCHEMA_SCHEMA_NAME;
								k = "schemaName";
				
				
							}else if( hv_exists(h,"nestedQuery",11) ){
								p->type = AR_MULTI_SCHEMA_NESTED_QUERY;
								k = "nestedQuery";
				
				
							}else if( hv_exists(h,"recursiveQuery",14) ){
								p->type = AR_MULTI_SCHEMA_RECURSIVE_QUERY;
								k = "recursiveQuery";
				
							}else{
							    ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: map error" );
							}
				
				
							switch( p->type ){
				
							case AR_MULTI_SCHEMA_SCHEMA_NAME:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "schemaName", 255 );
										val = hv_fetch( h, "schemaName", 10, 0 );
										if( val && *val && SvOK(*val) ){
											{
												strncpy( p->u.schemaName, SvPV_nolen(*val), sizeof(p->u.schemaName) );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schemaName\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_MULTI_SCHEMA_NESTED_QUERY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "nestedQuery", 255 );
										val = hv_fetch( h, "nestedQuery", 11, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.nestedQuery = MALLOCNN(sizeof(ARMultiSchemaNestedQueryStruct)); rev_ARMultiSchemaNestedQueryStruct( ctrl, h, k, p->u.nestedQuery );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"nestedQuery\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_MULTI_SCHEMA_RECURSIVE_QUERY:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "recursiveQuery", 255 );
										val = hv_fetch( h, "recursiveQuery", 14, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.recursiveQuery = MALLOCNN(sizeof(ARMultiSchemaRecursiveQueryStruct)); rev_ARMultiSchemaRecursiveQueryStruct( ctrl, h, k, p->u.recursiveQuery );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"recursiveQuery\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							default:
								sprintf( errText, "rev_ARMultiSchemaQueryFromStruct: invalid switch value %d", p->type );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "joinType", 255 );
						val = hv_fetch( h, "joinType", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->joinType = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"joinType\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "joinQual", 255 );
						val = hv_fetch( h, "joinQual", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->joinQual = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->joinQual );
							}
						}else{
							p->joinQual = NULL;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromAlias", 255 );
						val = hv_fetch( h, "queryFromAlias", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->queryFromAlias, SvPV_nolen(*val), sizeof(p->queryFromAlias) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromAlias\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaQueryFromStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaRecursiveFuncQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaRecursiveFuncQueryStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveFuncQueryStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaRecursiveFuncQueryStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "recursionQual", 255 );
						val = hv_fetch( h, "recursionQual", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->recursionQual = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->recursionQual );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"recursionQual\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "recursiveSchemaAlias", 255 );
						val = hv_fetch( h, "recursiveSchemaAlias", 20, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->recursiveSchemaAlias, SvPV_nolen(*val), sizeof(p->recursiveSchemaAlias) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"recursiveSchemaAlias\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "having", 255 );
						val = hv_fetch( h, "having", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->having = MALLOCNN(sizeof(ARMultiSchemaFuncQualifierStruct)); rev_ARMultiSchemaFuncQualifierStruct( ctrl, h, k, p->having );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"having\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "levelsToRetrieve", 255 );
						val = hv_fetch( h, "levelsToRetrieve", 16, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->levelsToRetrieve = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"levelsToRetrieve\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "startQual", 255 );
						val = hv_fetch( h, "startQual", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->startQual = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->startQual );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"startQual\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "groupBy", 255 );
						val = hv_fetch( h, "groupBy", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdList( ctrl, h, k, &(p->groupBy) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"groupBy\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromList", 255 );
						val = hv_fetch( h, "queryFromList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFuncQueryFromList( ctrl, h, k, &(p->queryFromList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "getListFuncs", 255 );
						val = hv_fetch( h, "getListFuncs", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldFuncList( ctrl, h, k, &(p->getListFuncs) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"getListFuncs\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveFuncQueryStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveFuncQueryStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveFuncQueryStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveFuncQueryStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaRecursiveQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaRecursiveQueryStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveQueryStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaRecursiveQueryStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "startQual", 255 );
						val = hv_fetch( h, "startQual", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->startQual = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->startQual );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"startQual\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromList", 255 );
						val = hv_fetch( h, "queryFromList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaQueryFromList( ctrl, h, k, &(p->queryFromList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "recursionQual", 255 );
						val = hv_fetch( h, "recursionQual", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->recursionQual = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->recursionQual );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"recursionQual\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "recursiveSchemaAlias", 255 );
						val = hv_fetch( h, "recursiveSchemaAlias", 20, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->recursiveSchemaAlias, SvPV_nolen(*val), sizeof(p->recursiveSchemaAlias) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"recursiveSchemaAlias\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "levelsToRetrieve", 255 );
						val = hv_fetch( h, "levelsToRetrieve", 16, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->levelsToRetrieve = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"levelsToRetrieve\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "getListFields", 255 );
						val = hv_fetch( h, "getListFields", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdList( ctrl, h, k, &(p->getListFields) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"getListFields\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveQueryStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveQueryStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveQueryStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRecursiveQueryStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaRelOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaRelOpStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRelOpStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaRelOpStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "left", 255 );
						val = hv_fetch( h, "left", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldValueOrArithStruct( ctrl, h, k, &(p->operandLeft) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"left\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "right", 255 );
						val = hv_fetch( h, "right", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldValueOrArithStruct( ctrl, h, k, &(p->operandRight) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"right\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "oper", 255 );
						val = hv_fetch( h, "oper", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),">") ){
									p->operation = AR_REL_OP_GREATER;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"in") ){
									p->operation = AR_REL_OP_IN;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),">=") ){
									p->operation = AR_REL_OP_GREATER_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"==") ){
									p->operation = AR_REL_OP_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"like") ){
									p->operation = AR_REL_OP_LIKE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"!=") ){
									p->operation = AR_REL_OP_NOT_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"<=") ){
									p->operation = AR_REL_OP_LESS_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"<") ){
									p->operation = AR_REL_OP_LESS;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARMultiSchemaRelOpStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"oper\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRelOpStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaRelOpStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaRelOpStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaRelOpStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaSortList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaSortList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaSortList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaSortList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->listPtr = (ARMultiSchemaSortStruct*) MALLOCNN( sizeof(ARMultiSchemaSortStruct) * num );
							/* if( p->listPtr == NULL ){
								croak( "rev_ARMultiSchemaSortList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARMultiSchemaSortStruct( ctrl, h, k, &(p->listPtr[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaSortList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaSortList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaSortList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaSortList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaSortList: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaSortStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaSortStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaSortStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaSortStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "sortOrder", 255 );
						val = hv_fetch( h, "sortOrder", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->sortOrder = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sortOrder\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdStruct( ctrl, h, k, &(p->fieldId) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaSortStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaSortStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaSortStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaSortStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaStatHistoryValue( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaStatHistoryValue *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaStatHistoryValue: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaStatHistoryValue: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "enumVal", 255 );
						val = hv_fetch( h, "enumVal", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->enumVal = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"enumVal\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromAlias", 255 );
						val = hv_fetch( h, "queryFromAlias", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->queryFromAlias, SvPV_nolen(*val), sizeof(p->queryFromAlias) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromAlias\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "userOrTime", 255 );
						val = hv_fetch( h, "userOrTime", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->userOrTime = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"userOrTime\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaStatHistoryValue: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaStatHistoryValue: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaStatHistoryValue: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaStatHistoryValue: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 17
int
rev_ARMultiSchemaValueSetFuncQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaValueSetFuncQueryStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetFuncQueryStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaValueSetFuncQueryStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "groupBy", 255 );
						val = hv_fetch( h, "groupBy", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdList( ctrl, h, k, &(p->groupBy) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"groupBy\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "qualifier", 255 );
						val = hv_fetch( h, "qualifier", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->qualifier = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->qualifier );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"qualifier\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromList", 255 );
						val = hv_fetch( h, "queryFromList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFuncQueryFromList( ctrl, h, k, &(p->queryFromList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdStruct( ctrl, h, k, &(p->fieldId) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "having", 255 );
						val = hv_fetch( h, "having", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->having = MALLOCNN(sizeof(ARMultiSchemaFuncQualifierStruct)); rev_ARMultiSchemaFuncQualifierStruct( ctrl, h, k, p->having );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"having\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetFuncQueryStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetFuncQueryStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetFuncQueryStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetFuncQueryStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 14
int
rev_ARMultiSchemaValueSetQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaValueSetQueryStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetQueryStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARMultiSchemaValueSetQueryStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "qualifier", 255 );
						val = hv_fetch( h, "qualifier", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->qualifier = MALLOCNN(sizeof(ARMultiSchemaQualifierStruct)); rev_ARMultiSchemaQualifierStruct( ctrl, h, k, p->qualifier );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"qualifier\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "queryFromList", 255 );
						val = hv_fetch( h, "queryFromList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaQueryFromList( ctrl, h, k, &(p->queryFromList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"queryFromList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMultiSchemaFieldIdStruct( ctrl, h, k, &(p->fieldId) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetQueryStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetQueryStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetQueryStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMultiSchemaValueSetQueryStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARNameList( ARControlStruct *ctrl, HV *h, char *k, ARNameList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARNameList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARNameList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->nameList = (ARNameType*) MALLOCNN( sizeof(ARNameType) * num );
							/* if( p->nameList == NULL ){
								croak( "rev_ARNameList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									strncpy( p->nameList[i], SvPV_nolen(*item), sizeof(p->nameList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARNameList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARNameList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARNameList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARNameList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARNameList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_AROpenDlgStruct( ARControlStruct *ctrl, HV *h, char *k, AROpenDlgStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AROpenDlgStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "AROpenDlgStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				#if AR_CURRENT_API_VERSION <= 9
					{
						SV **val;
						strncpy( k, "windowMode", 255 );
						val = hv_fetch( h, "windowMode", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"open_search") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_SEARCH;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dlg") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DLG;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dsply_detail") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DSPLY_DETAIL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_report") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_REPORT;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_modify_lst") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_MODIFY_LST;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_modify_detail") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_MODIFY_DETAIL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_modify_split") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_MODIFY_SPLIT;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dsply_split") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DSPLY_SPLIT;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dsply_lst") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DSPLY_LST;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_submit") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_SUBMIT;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_AROpenDlgStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"windowMode\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "vuiLabel", 255 );
						val = hv_fetch( h, "vuiLabel", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->vuiLabel, SvPV_nolen(*val), sizeof(p->vuiLabel) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"vuiLabel\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "reportString", 255 );
						val = hv_fetch( h, "reportString", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->reportString = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"reportString\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "suppressEmptyList", 255 );
						val = hv_fetch( h, "suppressEmptyList", 17, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"true") ){
									p->suppressEmptyLst = TRUE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"false") ){
									p->suppressEmptyLst = FALSE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_AROpenDlgStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"suppressEmptyList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "pollinginterval", 255 );
						val = hv_fetch( h, "pollinginterval", 15, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->pollinginterval = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"pollinginterval\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "targetLocation", 255 );
						val = hv_fetch( h, "targetLocation", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->targetLocation = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"targetLocation\"" );
							return -1;
						}
					}
				
				#if AR_CURRENT_API_VERSION >= 10
					{
						SV **val;
						strncpy( k, "windowMode", 255 );
						val = hv_fetch( h, "windowMode", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"open_modify") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_MODIFY;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dsply") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DSPLY;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_search") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_SEARCH;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dlg") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DLG;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dsply_detail") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DSPLY_DETAIL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_report") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_REPORT;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_modify_lst") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_MODIFY_LST;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_modify_detail") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_MODIFY_DETAIL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_modify_split") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_MODIFY_SPLIT;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dsply_split") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DSPLY_SPLIT;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_dsply_lst") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_DSPLY_LST;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"open_submit") ){
									p->windowMode = AR_ACTIVE_LINK_ACTION_OPEN_SUBMIT;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_AROpenDlgStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"windowMode\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "outputValueFieldPairs", 255 );
						val = hv_fetch( h, "outputValueFieldPairs", 21, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldAssignList( ctrl, h, k, &(p->outputValueFieldPairs) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"outputValueFieldPairs\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "query", 255 );
						val = hv_fetch( h, "query", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARQualifierStruct( ctrl, h, k, &(p->query) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"query\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "serverName", 255 );
						val = hv_fetch( h, "serverName", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->serverName, SvPV_nolen(*val), sizeof(p->serverName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"serverName\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "message", 255 );
						val = hv_fetch( h, "message", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARMessageStruct( ctrl, h, k, &(p->msg) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"message\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "noMatchContinue", 255 );
						val = hv_fetch( h, "noMatchContinue", 15, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"true") ){
									p->noMatchContinue = TRUE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"false") ){
									p->noMatchContinue = FALSE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_AROpenDlgStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"noMatchContinue\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "sortOrderList", 255 );
						val = hv_fetch( h, "sortOrderList", 13, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARSortList( ctrl, h, k, &(p->sortOrderList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sortOrderList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "inputValueFieldPairs", 255 );
						val = hv_fetch( h, "inputValueFieldPairs", 20, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldAssignList( ctrl, h, k, &(p->inputValueFieldPairs) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"inputValueFieldPairs\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "closeBox", 255 );
						val = hv_fetch( h, "closeBox", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"true") ){
									p->closeBox = TRUE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"false") ){
									p->closeBox = FALSE;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_AROpenDlgStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"closeBox\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schemaName", 255 );
						val = hv_fetch( h, "schemaName", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->schemaName, SvPV_nolen(*val), sizeof(p->schemaName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schemaName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AROpenDlgStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AROpenDlgStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_AROpenDlgStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_AROpenDlgStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 10
int
rev_ARPushFieldsActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARPushFieldsActionStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsActionStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARPushFieldsActionStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "sampleSchema", 255 );
						val = hv_fetch( h, "sampleSchema", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleSchema, SvPV_nolen(*val), sizeof(p->sampleSchema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleSchema\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "pushFieldsList", 255 );
						val = hv_fetch( h, "pushFieldsList", 14, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARPushFieldsList( ctrl, h, k, &(p->pushFieldsList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"pushFieldsList\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "sampleServer", 255 );
						val = hv_fetch( h, "sampleServer", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleServer, SvPV_nolen(*val), sizeof(p->sampleServer) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleServer\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsActionStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARPushFieldsActionStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARPushFieldsActionStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsActionStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARPushFieldsList( ARControlStruct *ctrl, HV *h, char *k, ARPushFieldsList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARPushFieldsList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->pushFieldsList = (ARPushFieldsStruct*) MALLOCNN( sizeof(ARPushFieldsStruct) * num );
							/* if( p->pushFieldsList == NULL ){
								croak( "rev_ARPushFieldsList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARPushFieldsStruct( ctrl, h, k, &(p->pushFieldsList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARPushFieldsList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARPushFieldsList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARPushFieldsStruct( ARControlStruct *ctrl, HV *h, char *k, ARPushFieldsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARPushFieldsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "assign", 255 );
						val = hv_fetch( h, "assign", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARAssignStruct( ctrl, h, k, &(p->assign) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"assign\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "field", 255 );
						val = hv_fetch( h, "field", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARAssignFieldStruct( ctrl, h, k, &(p->field) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"field\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARPushFieldsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARPushFieldsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARPushFieldsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARQualifierList( ARControlStruct *ctrl, HV *h, char *k, ARQualifierList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARQualifierList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->qualifierList = (ARQualifierStruct*) MALLOCNN( sizeof(ARQualifierStruct) * num );
							/* if( p->qualifierList == NULL ){
								croak( "rev_ARQualifierList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARQualifierStruct( ctrl, h, k, &(p->qualifierList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARQualifierList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARQualifierList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARQualifierStruct( ARControlStruct *ctrl, HV *h, char *k, ARQualifierStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARQualifierStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
					{
						char *pcase = NULL;
						char errText[512];
				
						HV *h;
						SV **hval = NULL;
						char *k   = NULL;
						if( SvTYPE(SvRV(*val)) != SVt_PVHV ){
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: not a hash value" );
							return -1;
						}
						h = (HV* ) SvRV((SV*) *val);
				
						hval = hv_fetch( h, "oper", 4, 0 );
				
							if( hval && *hval ){
								pcase = SvPV_nolen(*hval);
								if( 0 ){
				
								}else if( !strcmp(pcase,"and") ){
									p->operation = AR_COND_OP_AND;                 
				
				
								}else if( !strcmp(pcase,"external") ){
									p->operation = AR_COND_OP_FROM_FIELD;                 
				
				
								}else if( !strcmp(pcase,"not") ){
									p->operation = AR_COND_OP_NOT;                 
				
				
								}else if( !strcmp(pcase,"or") ){
									p->operation = AR_COND_OP_OR;                 
				
				
								}else if( !strcmp(pcase,"rel_op") ){
									p->operation = AR_COND_OP_REL_OP;                 
				
								}else{
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARQualifierStruct: key doesn't exist");
									ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, pcase );
									return -2;
								}
							}else{
								ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARQualifierStruct: hv_fetch (hval) returned null");
								return -2;
							}
				
				
							switch( p->operation ){
				
							case AR_COND_OP_AND:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "left", 255 );
										val = hv_fetch( h, "left", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandLeft = MALLOCNN(sizeof(ARQualifierStruct)); rev_ARQualifierStruct( ctrl, h, k, p->u.andor.operandLeft );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"left\"" );
											return -1;
										}
									}
								
								
									{
										SV **val;
										strncpy( k, "right", 255 );
										val = hv_fetch( h, "right", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandRight = MALLOCNN(sizeof(ARQualifierStruct)); rev_ARQualifierStruct( ctrl, h, k, p->u.andor.operandRight );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"right\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_REL_OP:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "rel_op", 255 );
										val = hv_fetch( h, "rel_op", 6, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.relOp = MALLOCNN(sizeof(ARRelOpStruct)); rev_ARRelOpStruct( ctrl, h, k, p->u.relOp );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"rel_op\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_NOT:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "not", 255 );
										val = hv_fetch( h, "not", 3, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.not = MALLOCNN(sizeof(ARQualifierStruct)); rev_ARQualifierStruct( ctrl, h, k, p->u.not );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"not\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_FROM_FIELD:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "fieldId", 255 );
										val = hv_fetch( h, "fieldId", 7, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.fieldId = SvIV(*val);
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
				
							case AR_COND_OP_OR:
								{
								
								
									if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
										int i = 0, num = 0;
										HV *h = (HV* ) SvRV((SV*) *val);
										char k[256];
										k[255] = '\0';
								
								
									{
										SV **val;
										strncpy( k, "left", 255 );
										val = hv_fetch( h, "left", 4, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandLeft = MALLOCNN(sizeof(ARQualifierStruct)); rev_ARQualifierStruct( ctrl, h, k, p->u.andor.operandLeft );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"left\"" );
											return -1;
										}
									}
								
								
									{
										SV **val;
										strncpy( k, "right", 255 );
										val = hv_fetch( h, "right", 5, 0 );
										if( val && *val && SvOK(*val) ){
											{
												p->u.andor.operandRight = MALLOCNN(sizeof(ARQualifierStruct)); rev_ARQualifierStruct( ctrl, h, k, p->u.andor.operandRight );
											}
										}else{
											ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"right\"" );
											return -1;
										}
									}
								
								
									}else{
										ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: hash value is not a hash reference" );
										return -1;
									}
								
								
								}
								break;
				
							case AR_COND_OP_NONE:
								break;
							default:
								sprintf( errText, "rev_ARQualifierStruct: invalid switch value %d", p->operation );
								ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, errText );
							}
				
					}
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARQualifierStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARQualifierStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARQueryValueStruct( ARControlStruct *ctrl, HV *h, char *k, ARQueryValueStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQueryValueStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARQueryValueStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "qualifier", 255 );
						val = hv_fetch( h, "qualifier", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->qualifier = MALLOCNN(sizeof(ARQualifierStruct)); rev_ARQualifierStruct( ctrl, h, k, p->qualifier );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"qualifier\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "multi", 255 );
						val = hv_fetch( h, "multi", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),"set") ){
									p->multiMatchCode = AR_QUERY_VALUE_MULTI_SET;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"error") ){
									p->multiMatchCode = AR_QUERY_VALUE_MULTI_ERROR;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"first") ){
									p->multiMatchCode = AR_QUERY_VALUE_MULTI_FIRST;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARQueryValueStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"multi\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "server", 255 );
						val = hv_fetch( h, "server", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->server, SvPV_nolen(*val), sizeof(p->server) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"server\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "valueField", 255 );
						val = hv_fetch( h, "valueField", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->valueField = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"valueField\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schema", 255 );
						val = hv_fetch( h, "schema", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->schema, SvPV_nolen(*val), sizeof(p->schema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schema\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQueryValueStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARQueryValueStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARQueryValueStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQueryValueStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARRealLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARRealLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARRealLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARRealLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "min", 255 );
						val = hv_fetch( h, "min", 3, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->rangeLow = SvNV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"min\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "max", 255 );
						val = hv_fetch( h, "max", 3, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->rangeHigh = SvNV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"max\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "precision", 255 );
						val = hv_fetch( h, "precision", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->precision = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"precision\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARRealLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARRealLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARRealLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARRealLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARReferenceList( ARControlStruct *ctrl, HV *h, char *k, ARReferenceList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARReferenceList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARReferenceList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->referenceList = (ARReferenceStruct*) MALLOCNN( sizeof(ARReferenceStruct) * num );
							/* if( p->referenceList == NULL ){
								croak( "rev_ARReferenceList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARReferenceStruct( ctrl, h, k, &(p->referenceList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARReferenceList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARReferenceList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARReferenceList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARReferenceList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARReferenceList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARRelOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARRelOpStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARRelOpStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARRelOpStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "left", 255 );
						val = hv_fetch( h, "left", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldValueOrArithStruct( ctrl, h, k, &(p->operandLeft) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"left\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "right", 255 );
						val = hv_fetch( h, "right", 5, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldValueOrArithStruct( ctrl, h, k, &(p->operandRight) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"right\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "oper", 255 );
						val = hv_fetch( h, "oper", 4, 0 );
						if( val && *val && SvOK(*val) ){
							{
								int flag = 0;
								if( !strcmp(SvPV_nolen(*val),">") ){
									p->operation = AR_REL_OP_GREATER;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"in") ){
									p->operation = AR_REL_OP_IN;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),">=") ){
									p->operation = AR_REL_OP_GREATER_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"==") ){
									p->operation = AR_REL_OP_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"like") ){
									p->operation = AR_REL_OP_LIKE;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"!=") ){
									p->operation = AR_REL_OP_NOT_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"<=") ){
									p->operation = AR_REL_OP_LESS_EQUAL;
									flag = 1;
								}
								if( !strcmp(SvPV_nolen(*val),"<") ){
									p->operation = AR_REL_OP_LESS;
									flag = 1;
								}
								if( flag == 0 ){
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL,  "rev_ARRelOpStruct: invalid key value" );
									ARError_add( AR_RETURN_ERROR, AP_ERR_CONTINUE, SvPV_nolen(*val) );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"oper\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARRelOpStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARRelOpStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARRelOpStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARRelOpStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARSQLStruct( ARControlStruct *ctrl, HV *h, char *k, ARSQLStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSQLStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARSQLStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "server", 255 );
						val = hv_fetch( h, "server", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->server, SvPV_nolen(*val), sizeof(p->server) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"server\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "command", 255 );
						val = hv_fetch( h, "command", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->command = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"command\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSQLStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARSQLStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARSQLStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSQLStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 10
int
rev_ARSetFieldsActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARSetFieldsActionStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSetFieldsActionStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARSetFieldsActionStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "sampleSchema", 255 );
						val = hv_fetch( h, "sampleSchema", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleSchema, SvPV_nolen(*val), sizeof(p->sampleSchema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleSchema\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "sampleServer", 255 );
						val = hv_fetch( h, "sampleServer", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleServer, SvPV_nolen(*val), sizeof(p->sampleServer) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleServer\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldList", 255 );
						val = hv_fetch( h, "fieldList", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARFieldAssignList( ctrl, h, k, &(p->fieldList) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldList\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSetFieldsActionStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARSetFieldsActionStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARSetFieldsActionStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSetFieldsActionStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARSortList( ARControlStruct *ctrl, HV *h, char *k, ARSortList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSortList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARSortList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->sortList = (ARSortStruct*) MALLOCNN( sizeof(ARSortStruct) * num );
							/* if( p->sortList == NULL ){
								croak( "rev_ARSortList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARSortStruct( ctrl, h, k, &(p->sortList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSortList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSortList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARSortList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARSortList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSortList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARSortStruct( ARControlStruct *ctrl, HV *h, char *k, ARSortStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSortStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARSortStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "sortOrder", 255 );
						val = hv_fetch( h, "sortOrder", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->sortOrder = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sortOrder\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "fieldId", 255 );
						val = hv_fetch( h, "fieldId", 7, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->fieldId = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldId\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSortStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARSortStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARSortStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARSortStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARStatusList( ARControlStruct *ctrl, HV *h, char *k, ARStatusList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARStatusList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARStatusList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->statusList = (ARStatusStruct*) MALLOCNN( sizeof(ARStatusStruct) * num );
							/* if( p->statusList == NULL ){
								croak( "rev_ARStatusList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARStatusStruct( ctrl, h, k, &(p->statusList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARStatusList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARStatusList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARStatusList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARStatusList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARStatusList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARTableLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARTableLimitsStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARTableLimitsStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARTableLimitsStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				#if AR_CURRENT_API_VERSION >= 10
					{
						SV **val;
						strncpy( k, "sampleSchema", 255 );
						val = hv_fetch( h, "sampleSchema", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleSchema, SvPV_nolen(*val), sizeof(p->sampleSchema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleSchema\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "numColumns", 255 );
						val = hv_fetch( h, "numColumns", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->numColumns = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"numColumns\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "qualifier", 255 );
						val = hv_fetch( h, "qualifier", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARQualifierStruct( ctrl, h, k, &(p->qualifier) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"qualifier\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "maxRetrieve", 255 );
						val = hv_fetch( h, "maxRetrieve", 11, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->maxRetrieve = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"maxRetrieve\"" );
							return -1;
						}
					}
				
				#if AR_CURRENT_API_VERSION >= 10
					{
						SV **val;
						strncpy( k, "sampleServer", 255 );
						val = hv_fetch( h, "sampleServer", 12, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->sampleServer, SvPV_nolen(*val), sizeof(p->sampleServer) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"sampleServer\"" );
							return -1;
						}
					}
				#endif
				
					{
						SV **val;
						strncpy( k, "server", 255 );
						val = hv_fetch( h, "server", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->server, SvPV_nolen(*val), sizeof(p->server) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"server\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "schema", 255 );
						val = hv_fetch( h, "schema", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->schema, SvPV_nolen(*val), sizeof(p->schema) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"schema\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARTableLimitsStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARTableLimitsStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARTableLimitsStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARTableLimitsStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARUnsignedIntList( ARControlStruct *ctrl, HV *h, char *k, ARUnsignedIntList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARUnsignedIntList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARUnsignedIntList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->intList = (unsigned int*) MALLOCNN( sizeof(unsigned int) * num );
							/* if( p->intList == NULL ){
								croak( "rev_ARUnsignedIntList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									p->intList[i] = SvIV(*item);
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARUnsignedIntList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARUnsignedIntList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARUnsignedIntList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARUnsignedIntList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARUnsignedIntList: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARValueList( ARControlStruct *ctrl, HV *h, char *k, ARValueList *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARValueList: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARValueList: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
					{
						if( SvTYPE(SvRV(*val)) == SVt_PVAV ){
							int i = 0, num = 0;
							AV *ar = (AV*) SvRV((SV*) *val);
				
							num = av_len(ar) + 1;
							p->numItems = num;
							if( num == 0 ) return 0;
				
							p->valueList = (ARValueStruct*) MALLOCNN( sizeof(ARValueStruct) * num );
							/* if( p->valueList == NULL ){
								croak( "rev_ARValueList: malloc error\n" );
								exit( 1 );
							} */
				
							for( i = 0; i < num; ++i ){
								SV **item = av_fetch( ar, i, 0 );
				
								if( item && *item ){
									char *k = "_";
									HV *h = newHV();
									
									SvREFCNT_inc( *item );
				                    hv_store( h, k, strlen(k), *item, 0 );
				
									rev_ARValueStruct( ctrl, h, k, "dataType", &(p->valueList[i]) );
									hv_undef( h );
								}else{
									ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARValueList: invalid inner array value" );
								}
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARValueList: hash value is not an array reference" );
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, k );
							return -1;
						}
					}
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARValueList: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARValueList: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARValueList: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 8
int
rev_ARVendorMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARVendorMappingStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARVendorMappingStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARVendorMappingStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "fieldName", 255 );
						val = hv_fetch( h, "fieldName", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->fieldName, SvPV_nolen(*val), sizeof(p->fieldName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARVendorMappingStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARVendorMappingStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARVendorMappingStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARVendorMappingStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 8
int
rev_ARVendorSchema( ARControlStruct *ctrl, HV *h, char *k, ARVendorSchema *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARVendorSchema: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARVendorSchema: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "tableName", 255 );
						val = hv_fetch( h, "tableName", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->tableName, SvPV_nolen(*val), sizeof(p->tableName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"tableName\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "vendorName", 255 );
						val = hv_fetch( h, "vendorName", 10, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->vendorName, SvPV_nolen(*val), sizeof(p->vendorName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"vendorName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARVendorSchema: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARVendorSchema: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARVendorSchema: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARVendorSchema: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif


#if AR_CURRENT_API_VERSION >= 8
int
rev_ARViewLimits( ARControlStruct *ctrl, HV *h, char *k, ARViewLimits *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewLimits: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARViewLimits: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "maxLength", 255 );
						val = hv_fetch( h, "maxLength", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->maxLength = SvIV(*val);
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"maxLength\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewLimits: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARViewLimits: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARViewLimits: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewLimits: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif



int
rev_ARViewMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARViewMappingStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewMappingStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARViewMappingStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "fieldName", 255 );
						val = hv_fetch( h, "fieldName", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->fieldName, SvPV_nolen(*val), sizeof(p->fieldName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"fieldName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewMappingStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARViewMappingStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARViewMappingStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewMappingStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARViewSchema( ARControlStruct *ctrl, HV *h, char *k, ARViewSchema *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewSchema: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARViewSchema: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "keyField", 255 );
						val = hv_fetch( h, "keyField", 8, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->keyField, SvPV_nolen(*val), sizeof(p->keyField) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"keyField\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "tableName", 255 );
						val = hv_fetch( h, "tableName", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								strncpy( p->tableName, SvPV_nolen(*val), sizeof(p->tableName) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"tableName\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewSchema: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARViewSchema: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARViewSchema: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARViewSchema: first argument is not a hash");
		return -1;
	}

	return 0;
}




int
rev_ARWaitStruct( ARControlStruct *ctrl, HV *h, char *k, ARWaitStruct *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARWaitStruct: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARWaitStruct: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "continueButtonTitle", 255 );
						val = hv_fetch( h, "continueButtonTitle", 19, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->continueButtonTitle = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"continueButtonTitle\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARWaitStruct: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARWaitStruct: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARWaitStruct: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARWaitStruct: first argument is not a hash");
		return -1;
	}

	return 0;
}



#if AR_CURRENT_API_VERSION >= 11
int
rev_ARXMLEntryReturn( ARControlStruct *ctrl, HV *h, char *k, ARXMLEntryReturn *p ){
	SV  **val;
	int i = 0;

	if( !p ){
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARXMLEntryReturn: AR Object param is NULL" );
		return -1;
	}

	if( SvTYPE((SV*) h) == SVt_PVHV ){

		// printf( "ARXMLEntryReturn: k = <%s>\n", k );
		if( hv_exists(h,k,strlen(k)) ){
			val = hv_fetch( h, k, strlen(k), 0 );
			if( val && *val ){
				{
				
				
					if( SvTYPE(SvRV(*val)) == SVt_PVHV ){
						int i = 0, num = 0;
						HV *h = (HV* ) SvRV((SV*) *val);
						char k[256];
						k[255] = '\0';
				
				
					{
						SV **val;
						strncpy( k, "status", 255 );
						val = hv_fetch( h, "status", 6, 0 );
						if( val && *val && SvOK(*val) ){
							{
								rev_ARStatusList( ctrl, h, k, &(p->status) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"status\"" );
							return -1;
						}
					}
				
				
					{
						SV **val;
						strncpy( k, "outputDoc", 255 );
						val = hv_fetch( h, "outputDoc", 9, 0 );
						if( val && *val && SvOK(*val) ){
							{
								p->outputDoc = strdup( SvPV_nolen(*val) );
							}
						}else{
							ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "hv_fetch error: key \"outputDoc\"" );
							return -1;
						}
					}
				
				
					}else{
						ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARXMLEntryReturn: hash value is not a hash reference" );
						return -1;
					}
				
				
				}
			}else{
				ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARXMLEntryReturn: hv_fetch returned null");
				return -2;
			}
		}else{
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, "rev_ARXMLEntryReturn: key doesn't exist");
			ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, k );
			return -2;
		}
	}else{
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARXMLEntryReturn: first argument is not a hash");
		return -1;
	}

	return 0;
}
#endif





void copyIntArray( int size, int *dst, SV* src ){
	AV *ar = (AV*) SvRV((SV*) src);
	int len = av_len(ar);
	int i;
	for( i = 0; i < size; ++i ){
		dst[i] = 0;
		if( i <= len ){ 
			SV** item = av_fetch( ar, i, 0 );
			if( item != NULL && *item != NULL && i <= len ){
				dst[i] = (SvOK(*item))? SvIV(*item) : 0;
			}
		}
	}
}

void copyUIntArray( int size, ARInternalId *dst, SV* src ){
	AV *ar = (AV*) SvRV((SV*) src);
	int len = av_len(ar);
	int i;
	for( i = 0; i < size; ++i ){
		dst[i] = 0;
		if( i <= len ){ 
			SV** item = av_fetch( ar, i, 0 );
			if( item != NULL && *item != NULL && i <= len ){
				dst[i] = (SvOK(*item))? SvUV(*item) : 0;
			}
		}
	}
}



