/* key_utils.i */
%module "Business::OnlinePayment::BitPay::KeyUtils"
%apply char *OUTPUT { char **pem }; 
%{
#include "bitpay.h"
extern int generatePem(char **pem);
extern int generateSinFromPem(char *pem, char **sin);
extern int getPublicKeyFromPem(char *pemstring, char **pubkey);
extern int signMessageWithPem(char *pem, char *message, char **signature); 
%}

extern int generatePem(char **pem);
extern int generateSinFromPem(char *pem, char **sin);
extern int getPublicKeyFromPem(char *pemstring, char **pubkey);
extern int signMessageWithPem(char *pem, char *message, char **signature); 

%newobject bpGeneratePem;
%newobject bpGenerateSinFromPem;
%newobject bpGetPublicKeyFromPem;
%newobject bpSignMessageWithPem;

%inline %{
	char *bpSignMessageWithPem(char *pem, char *message) {
		char *ret = malloc(145);
		char *err = malloc(5);
		int errorCode;

		memcpy(err, "ERROR", 5);

		errorCode = signMessageWithPem(message, pem, &ret);
		char *signature = ret;

		if (errorCode == NOERROR) {
			return signature;
		} else {
			return err;
		}
		
	}
%}

%inline %{
	char *bpGeneratePem() {
		char *ret = malloc(240);
		char *err = "ERROR";
		int errorCode;

		errorCode = generatePem(&ret);
		char *pem = ret;

		if (errorCode == NOERROR) {
			return pem;
		} else {
			return err;
		}
		
	}
%}

%inline %{
	char *bpGenerateSinFromPem(char *pem) {
		char *ret = malloc(sizeof(char)*36);
		char *err = "ERROR";
		int errorCode;

		errorCode = generateSinFromPem(pem, &ret);

		if (errorCode == NOERROR) {
			return ret;
		} else {
			return err;
		}
		
	}
%}

%inline %{
	char *bpGetPublicKeyFromPem(char *pem) {
		char *ret = malloc(67);
		char *err = malloc(5);
		int errorCode;

		memcpy(err, "ERROR", 5);

		errorCode = getPublicKeyFromPem(pem, &ret);
		char *pub = ret;

		if (errorCode == NOERROR) {
			return pub;
		} else {
			return err;
		}
		
	}
%}
