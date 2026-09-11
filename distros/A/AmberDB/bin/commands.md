# AmberDB Commands & Cheat-Sheet

## Setup & Maintenance
```bash
perl bin/amberdb_setup.pl --action=reindex
perl bin/amberdb_setup.pl --action=ramdisk --start
perl bin/amberdb_setup.pl --action=install --user=eticaretim --size=512M
perl bin/amberdb_setup.pl --action=update
perl bin/amberdb_setup.pl --action=update-amberdb --check
perl bin/amberdb_setup.pl --action=update-storage --all
```

## AmberDB CLI (amberdb & bin/amberdb_cli.pl)

### 1. Durum & Tablolar (Dashboard)
```bash
amberdb
amberdb tables
amberdb tables json
```

### 2. Doğrudan (Oturumsuz / Stateless) Kullanım
```bash
# Tekil okuma:
amberdb read products 10
amberdb read products 10 inflate=1 json

# Sayfalamalı okuma:
amberdb read products all 0 20
amberdb read products all 0 50 keys_only=1 sort=-3
amberdb read sales_price all 0 10 json time  # Geçen süreyi en altta gösterir

# Çoklu ID okuma:
amberdb read users 1,2,5,10 json

# Tam metin ve fonetik arama:
amberdb search products "kablosuz kulaklik" limit=10
amberdb search catalog_product "türkiye" 0 10 keys_only=1 time
amberdb search products "sony" filter=3:54 limit=5 json

# Blok alan değeri filtreleme:
amberdb fetch orders 2 "completed" json

# Şema yapısını inceleme:
amberdb info products

# Toplam kayıt sayısı:
amberdb count products

# Ekleme, güncelleme, silme:
amberdb insert users 0 data='{"name":"Ahmet"}'
amberdb update users 10 data='{"status":2}'
amberdb delete users 10
```

### 3. Oturum Komutları (Session Management - 4 Haneli Token)
```bash
# Oturum açar (örn: Token 1245):
amberdb connect path-dbase_dir=dbstore

# Oturumda tablo şema niteliğini belirleme:
amberdb 1245 attr products search_block=[1] keep_deleted=1
amberdb 1245 attr products

# Oturumda sorgu çalıştırma:
amberdb 1245 search products "kablosuz kulaklik"
amberdb 1245 read products 10 json

# Oturum ayarları (config & path):
amberdb 1245 config no_write=1
amberdb 1245 path dbase_dir=/var/data

# Oturumu sonlandırma:
amberdb 1245 disconnect
```

### 4. Bakım ve Yönetim Eylemleri
```bash
amberdb reindex products
amberdb check products
amberdb vacuum products
amberdb export products file=products.csv
amberdb import products file=products.csv
amberdb dump products file=backup.tar.gz
amberdb restore file=backup.tar.gz force=1
amberdb rename from=old_table to=new_table
amberdb drop temp_table --force
```
