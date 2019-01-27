#!/bin/sh

perlambda dist --clean . func.zip

perlambda create \
  --region=ap-northeast-1 \
  --aws_account=123456789012 \
  --iam_name=YOUR-IAM-ROLE \
  --func_name=YOUR-FUNC-NAME \
  --handler=handler.handle \
  --zip=./func.zip \
  --layer_version=1

perlambda update --region=ap-northeast-1 perl-simple func.zip

