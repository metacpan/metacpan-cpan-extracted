# NAME

App::Greple::xlate - módulo de traducción para greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.20

# DESCRIPTION

El módulo **Greple** **xlate** encuentra bloques de texto y los reemplaza por el texto traducido. Actualmente sólo DeepL servicio es compatible con el módulo **xlate::deepl**.

Si desea traducir un bloque de texto normal en un documento de estilo [pod](https://metacpan.org/pod/pod), utilice el comando **greple** con el módulo `xlate::deepl` y `perl` de la siguiente manera:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

El patrón `^(\w.*\n)+` significa líneas consecutivas que comienzan con una letra alfanumérica. Este comando muestra el área a traducir. La opción **--all** se utiliza para producir el texto completo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

A continuación, añada la opción `--xlate` para traducir el área seleccionada. Las encontrará y reemplazará por la salida del comando **deepl**.

Por defecto, el texto original y traducido se imprime en el formato "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Usando el formato `ifdef`, puede obtener fácilmente la parte deseada mediante el comando [unifdef(1)](http://man.he.net/man1/unifdef). El formato puede especificarse mediante la opción **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si desea traducir todo el texto, utilice la opción **--match-all**. Es un atajo para especificar que el patrón coincide con todo el texto `(?s).+`.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoca el proceso de traducción para cada área coincidente.

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Por lo tanto, puede comprobar qué parte del archivo será objeto de la traducción antes de invocar el trabajo real.

    El resultado del comando va a la salida estándar, así que rediríjalo al archivo si es necesario, o considere usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=nunca**.

    Con la opción **--xlate-fold**, el texto convertido se dobla por el ancho especificado. La anchura por defecto es 70 y puede ajustarse con la opción **--xlate-fold-width**. Se reservan cuatro columnas para la operación de repliegue, por lo que cada línea puede contener 74 caracteres como máximo.

- **--xlate-engine**=_engine_

    Especifique el motor de traducción que se utilizará. No es necesario utilizar esta opción porque el módulo `xlate::deepl` lo declara como `--xlate-engine=deepl`.

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que trabaje para. Después de preparar el texto a traducir, se copian en el portapapeles. Se espera que los pegue en el formulario, copie el resultado en el portapapeles y pulse Retorno.

- **--xlate-to** (Default: `EN-US`)

    Especifique el idioma de destino. Puede obtener los idiomas disponibles mediante el comando `deepl languages` si utiliza el motor **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifique el formato de salida del texto original y traducido.

    - **conflict**, **cm**

        Imprima el texto original y traducido en formato de marcador de conflicto [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puede recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Imprime el texto original y traducido en formato [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puede recuperar sólo el texto japonés mediante el comando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Imprime el texto original y el traducido separados por una sola línea en blanco.

    - **xtxt**

        Si el formato es `xtxt` (texto traducido) o desconocido, sólo se imprime el texto traducido.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Especifique la longitud máxima del texto que se enviará a la API de una sola vez. El valor predeterminado es el mismo que para el servicio de cuenta gratuita: 128K para la API (**--xlate**) y 5000 para la interfaz del portapapeles (**--xlate-labor**). Puede cambiar estos valores si utiliza el servicio Pro.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Ver el resultado de la traducción en tiempo real en la salida STDERR.

- **--match-all**

    Establece todo el texto del fichero como área de destino.

# CACHE OPTIONS

El módulo **xlate** puede almacenar en caché el texto traducido de cada fichero y leerlo antes de la ejecución para eliminar la sobrecarga de preguntar al servidor. Con la estrategia de caché por defecto `auto`, mantiene los datos de caché sólo cuando el archivo de caché existe para el archivo de destino.

- --cache-clear

    La opción **--cache-clear** puede utilizarse para iniciar la gestión de la caché o para refrescar todos los datos de caché existentes. Una vez ejecutada esta opción, se creará un nuevo archivo de caché si no existe y se mantendrá automáticamente después.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mantener el archivo de caché si existe.

    - `create`

        Crear un archivo de caché vacío y salir.

    - `always`, `yes`, `1`

        Mantener caché de todos modos hasta que el destino sea un archivo normal.

    - `clear`

        Borrar primero los datos de la caché.

    - `never`, `no`, `0`

        No utilizar nunca el archivo de caché aunque exista.

    - `accumulate`

        Por defecto, los datos no utilizados se eliminan del archivo de caché. Si no desea eliminarlos y mantenerlos en el archivo, utilice `acumular`.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Establezca su clave de autenticación para el servicio DeepL.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Librería Python y comando CLI.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vea el manual **greple** para los detalles sobre el patrón de texto objetivo. Utilice las opciones **--inside**, **--outside**, **--include**, **--exclude** para limitar el área de coincidencia.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puede utilizar el módulo `-Mupdate` para modificar archivos según el resultado del comando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilice **sdif** para mostrar el formato del marcador de conflicto junto con la opción **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
